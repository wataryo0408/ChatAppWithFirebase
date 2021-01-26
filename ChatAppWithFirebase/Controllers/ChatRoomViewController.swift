//
//  ChatRoomViewController.swift
//  ChatAppWithFirebase
//
//  Created by 渡邉凌 on 2021/01/15.
//

import Foundation
import UIKit
import Firebase

class ChatRoomViewController: UIViewController{
    
    var user: User?
    var chatRoom: ChatRoom?
    
    
    private var messages = [Message]()
    private let cellId = "cellId"
    
    private lazy var chatInputAccessoryView: ChatInputAccessoryView = {
        let view = ChatInputAccessoryView()
        view.frame = .init(x: 0, y: 0, width: view.frame.width, height: 100)
        view.delegate = self
        return view
    }()
    
    
    @IBOutlet weak var chatRoomTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotification()
        setupChatRoomTableView()
        fetchMessages()
    }
    
    private func setupNotification(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    private func setupChatRoomTableView(){
        
        chatRoomTableView.delegate = self
        chatRoomTableView.dataSource = self
        chatRoomTableView.register(UINib(nibName: "ChatRoomTableViewCell", bundle: nil), forCellReuseIdentifier: cellId)
        chatRoomTableView.backgroundColor = .rgb(red: 118, green: 140, blue: 180)
        chatRoomTableView.contentInset = .init(top: 60, left: 0, bottom: 0, right: 0)
        chatRoomTableView.scrollIndicatorInsets = .init(top: 60, left: 0, bottom: 40, right: 0)
        chatRoomTableView.keyboardDismissMode = .interactive
        chatRoomTableView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
    }
    
    @objc func keyboardWillShow(){
        print("keyboardWillShow")
    }
    
    @objc func keyboardWillHide(){
        print("keyboardWillHide")
        
    }
    override var inputAccessoryView: UIView?{
        get{
            return chatInputAccessoryView
        }
    }
    override var canBecomeFirstResponder: Bool{
        return true
    }
    
    private func fetchMessages(){
        guard let documentDocId = chatRoom?.documentId else { return }
        
        Firestore.firestore().collection("chatRooms").document(documentDocId).collection("messages").addSnapshotListener { (snapshpt, err) in
            if let err = err{
                print("message情報の取得に失敗しました。\(err)")
            }
            snapshpt?.documentChanges.forEach({ (documentChange) in
                switch documentChange.type{
                case .added:
                    let dic = documentChange.document.data()
                    let message = Message(dic: dic)
                    message.partnerUser = self.chatRoom?.partnerUser
                    self.messages.append(message)
                    self.messages.sort { (m1, m2) -> Bool in
                        let m1Date = m1.createdAt.dateValue()
                        let m2Date = m2.createdAt.dateValue()
                        return m1Date > m2Date
                    }
                    self.chatRoomTableView.reloadData()
//                    self.chatRoomTableView.scrollToRow(at: IndexPath(row: self.messages.count - 1, section: 0), at: .bottom, animated: true)
                    print("message dic:", dic)
                    
                case .modified, .removed:
                    print("nothing to do")
                    
                }
            })
        }
    }
}



//MARK: - ChatRoomViewController, ChatInputAccessoryViewDelegate
extension ChatRoomViewController: ChatInputAccessoryViewDelegate{
    func tappedSendButton(text: String) {
        addMessageToFirebsse(text: text)
    }
    private func addMessageToFirebsse(text: String){
        guard let documentDocId = chatRoom?.documentId else { return }
        guard let name = user?.username else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        chatInputAccessoryView.removeText()
        
        let messageId = randomString(length: 20)
        
        let docData = [
            
            "name": name,
            "createdAt": Timestamp(),
            "uid": uid,
            "message": text
        ] as [String: Any]
        
        Firestore.firestore().collection("chatRooms").document(documentDocId).collection("messages").document(messageId).setData(docData) { (err) in
            if let err = err{
                print("message情報の保存に失敗しました。\(err)")
                return
            }
            
            let latestMessageData = [
                "latestMessageId": messageId
            ]
            
            Firestore.firestore().collection("chatRooms").document(documentDocId).updateData(latestMessageData) { (err) in
                if let err = err{
                    print("最新メッセージの保存に失敗しました。\(err)")
                    return
                }
                print("messageの保存に成功しました。")
            }
        }
    }
    
    func randomString(length: Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        return randomString
    }
}
//MARK: - UITableViewDelegate, UITableViewDataSource
extension ChatRoomViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        chatRoomTableView.estimatedRowHeight = 20
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = chatRoomTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ChatRoomTableViewCell
        cell.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        cell.message = messages[indexPath.row]
        return cell
    }
    
    
    
}
