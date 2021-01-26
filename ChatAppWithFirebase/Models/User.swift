//
//  User.swift
//  ChatAppWithFirebase
//
//  Created by 渡邉凌 on 2021/01/17.
//

import Foundation
import Firebase
import FirebaseFirestore

class User {
    let email: String
    let username: String
    let createdAt: Timestamp
    let profileImageUrl: String
    
    var uid: String?
    
    init(dic: [String: Any]) {
        self.email = dic["email"] as? String ?? ""
        self.username = dic["username"] as? String ?? ""
        self.createdAt = dic["createdAt"] as? Timestamp ?? Timestamp()
        self.profileImageUrl = dic["profileImageUrl"] as? String ?? ""

    }
}
