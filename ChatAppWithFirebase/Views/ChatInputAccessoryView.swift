//
//  ChatInputAccessoryView.swift
//  ChatAppWithFirebase
//
//  Created by 渡邉凌 on 2021/01/15.
//

import Foundation
import UIKit

protocol ChatInputAccessoryViewDelegate: class {
    func tappedSendButton(text: String)
}

class ChatInputAccessoryView: UIView{
    
    @IBOutlet weak var chatTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBAction func tappedSendButton(_ sender: Any) {
        guard let text = chatTextView.text else { return }
        delegate?.tappedSendButton(text: text)
        print("tapped SendButton")
    }
    
    weak var delegate: ChatInputAccessoryViewDelegate?
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        nibinit()
        setupViews()
        autoresizingMask = .flexibleHeight
    }
    
    private func setupViews(){
        chatTextView.layer.cornerRadius = 15
        chatTextView.layer.borderColor = UIColor.rgb(red: 230, green: 230, blue: 230).cgColor
        chatTextView.backgroundColor = UIColor.rgb(red: 250, green: 250, blue: 250)
        chatTextView.layer.borderWidth = 1
        chatTextView.text = ""
        chatTextView.delegate = self
        sendButton.layer.cornerRadius = 15
        sendButton.imageView?.contentMode = .scaleAspectFill
        sendButton.contentHorizontalAlignment = .fill
        sendButton.contentVerticalAlignment = .fill
        sendButton.isEnabled = false
        
    }
    
    func removeText(){
        chatTextView.text = ""
        sendButton.isEnabled = false
    }
    
    override var intrinsicContentSize: CGSize{
        return .zero
    }
    
    private func nibinit(){
        let nib = UINib(nibName: "ChatInputAccessoryView", bundle: nil)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.addSubview(view)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
//MARK: - UITextViewDelegate
extension ChatInputAccessoryView: UITextViewDelegate{
    
    func textViewDidChange(_ textView: UITextView) {
        print("chatTextView.text（入力された文字）: ",textView.text)
        if textView.text.isEmpty{
            sendButton.isEnabled = false
        }else{
            sendButton.isEnabled = true
        }
    }
}
