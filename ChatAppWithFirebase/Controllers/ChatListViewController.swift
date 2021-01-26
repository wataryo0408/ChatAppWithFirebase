//
//  ChatListViewController.swift
//  ChatAppWithFirebase
//
//  Created by 渡邉凌 on 2021/01/15.
//

import Foundation
import UIKit
import Firebase
import FirebaseFirestore
import Nuke


class ChatListViewController: UIViewController{
    
    private let cellId = "cellId"
    private var chatRooms = [ChatRoom]()
    private var chatRoomListener: ListenerRegistration?
    
    private var user: User?{
        didSet{
            navigationItem.title = user?.username
        }
    }
    @IBOutlet weak var chatListTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        confirmLoggedInUser()
        fetchChatroomsInfoFromFirestore()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchLoginUserInfo()
        
    }
    
    func fetchChatroomsInfoFromFirestore(){
        chatRoomListener?.remove()
        chatRooms.removeAll()
        chatListTableView.reloadData()
        
        chatRoomListener = Firestore.firestore().collection("chatRooms")
            .addSnapshotListener { (snapshot, err) in
                if let err = err{
                    print("chatRoom情報の取得に失敗しました。\(err)")
                    return
                }
                snapshot?.documentChanges.forEach({ (documentChange) in
                    switch documentChange.type{
                    case .added:
                        self.handleAddedDocumentChange(documentChange: documentChange)
                        
                    case .modified, .removed:
                        print("nothing to do")
                        
                    }
                })
            }
    }
    
    private func handleAddedDocumentChange(documentChange: DocumentChange){
        
        let dic = documentChange.document.data()
        let chatRoom = ChatRoom(dic: dic)
        chatRoom.documentId = documentChange.document.documentID
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let isContain = chatRoom.members.contains(uid)
        if !isContain { return }
        chatRoom.members.forEach { (memberUid) in
            if memberUid != uid{
                Firestore.firestore().collection("users").document(memberUid).getDocument { (userSnapshot, err) in
                    if let err = err{
                        print("ユーザー情報の取得に失敗しました。\(err)")
                        return
                    }
                    
                    guard let dic = userSnapshot?.data() else { return }
                    let user = User(dic: dic)
                    user.uid = documentChange.document.documentID
                    chatRoom.partnerUser = user
                    
                    
                    guard let chatRoomId = chatRoom.documentId else { return }
                    let latestMessageId = chatRoom.latestMessageId
                    
                    if latestMessageId == ""{
                        self.chatRooms.append(chatRoom)
                        self.chatListTableView.reloadData()
                        return
                    }
                    
                    Firestore.firestore().collection("chatRooms").document(chatRoomId).collection("messages").document(latestMessageId).getDocument { (messageSnapshot, err) in
                        if let err = err{
                            print("最新情報の取得に失敗しました。\(err)")
                            return
                        }
                        
                        guard let dic = messageSnapshot?.data() else { return }
                        let message = Message(dic: dic)
                        chatRoom.latestMessage = message
                        
                        self.chatRooms.append(chatRoom)
                        self.chatListTableView.reloadData()
                    }
                }
            }
        }
    }
    
    private func setupViews(){
        chatListTableView.tableFooterView = UIView()
        chatListTableView.delegate = self
        chatListTableView.dataSource = self
        navigationController?.navigationBar.barTintColor = .rgb(red: 39, green: 49, blue: 69)
        navigationItem.title = "トーク"
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        let rightBarButton = UIBarButtonItem(title: "新規チャット", style: .plain, target: self, action: #selector(tappedNavRightBarButton))
        let logoutBarButton = UIBarButtonItem(title: "ログアウト", style: .plain, target: self, action: #selector(tappedLogoutButton))
        navigationItem.rightBarButtonItem = rightBarButton
        navigationItem.rightBarButtonItem?.tintColor = .white
        navigationItem.leftBarButtonItem = logoutBarButton
        navigationItem.leftBarButtonItem?.tintColor = .white
    }
    
    private func confirmLoggedInUser(){
        if Auth.auth().currentUser?.uid == nil{
            pushLoginViewController()
        }
    }
    
    private func pushLoginViewController(){
        let storyboard = UIStoryboard(name: "SignUp", bundle: nil)
        let signUpViewController = storyboard.instantiateViewController(withIdentifier: "SignUpViewController") as! SignUpViewController
        let nav = UINavigationController(rootViewController: signUpViewController)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc private func tappedNavRightBarButton(){
        print("tappedNavLightBarButton")
        let storyboard = UIStoryboard.init(name: "UserList", bundle: nil)
        let userListViewContoller = storyboard.instantiateViewController(withIdentifier: "UserListViewController")
        let nav = UINavigationController(rootViewController: userListViewContoller)
        self.present(nav, animated: true, completion: nil)
    }
    @objc private func tappedLogoutButton(){
        do{
            try Auth.auth().signOut()
            pushLoginViewController()
        } catch {
            print("ログアウトに失敗しました。\(error)")
        }
    }
    
    private func fetchLoginUserInfo(){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("users").document(uid).getDocument { (snapshot, err) in
            if let err = err{
                print("ユーザー情報の取得に失敗しました。\(err)")
                return
            }
            
            guard let snapshot = snapshot, let dic = snapshot.data() else { return }
            
            let user = User(dic: dic)
            self.user = user
        }
    }
}
//MARK: - UITableViewDelegate, UITableViewDataSource
extension ChatListViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    //セルの数を返す
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = chatListTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ChatListTableViewCell
        cell.chatRoom = chatRooms[indexPath.row]
        
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("tapped table view")
        let storyboard = UIStoryboard.init(name: "ChatRoom", bundle: nil)
        let chatRoomViewController = storyboard.instantiateViewController(withIdentifier: "ChatRoomViewController") as! ChatRoomViewController
        chatRoomViewController.user = user
        chatRoomViewController.chatRoom = chatRooms[indexPath.row]
        navigationController?.pushViewController(chatRoomViewController, animated: true)
    }
}


class ChatListTableViewCell: UITableViewCell{
    
    var chatRoom: ChatRoom?{
        didSet{
            if let chatRoom = chatRoom{
                partnerLabel.text = chatRoom.partnerUser?.username
                
                guard let url = URL(string: chatRoom.partnerUser?.profileImageUrl ?? "") else { return }
                
                Nuke.loadImage(with: url, into: userImageView)
                
                dateLabel.text = dateFormatterForDateLabel(date: chatRoom.latestMessage?.createdAt.dateValue() ?? Date())
                latestMessageLabel.text = chatRoom.latestMessage?.message
            }
            
        }
    }
    
    
    @IBOutlet weak var partnerLabel: UILabel!
    @IBOutlet weak var latestMessageLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        userImageView.layer.cornerRadius = 30
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private func dateFormatterForDateLabel(date: Date) -> String{
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
