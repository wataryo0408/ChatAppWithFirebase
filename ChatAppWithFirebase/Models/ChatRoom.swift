//
//  ChatRoom.swift
//  ChatAppWithFirebase
//
//  Created by 渡邉凌 on 2021/01/20.
//

import Foundation
import Firebase

class ChatRoom {
    let latestMessageId: String
    let members: [String]
    let createdAt: Timestamp
    
    var latestMessage: Message?
    var partnerUser: User?
    var documentId: String?
    
    init(dic: [String: Any]) {
        self.latestMessageId = dic["latestMessageId"] as? String ?? ""
        self.members = dic["members"] as? [String] ?? [String]()
        self.createdAt = dic["createdAt"] as? Timestamp ?? Timestamp()
    }
}
