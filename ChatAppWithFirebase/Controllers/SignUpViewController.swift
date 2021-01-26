//
//  SignUpViewController.swift
//  ChatAppWithFirebase
//
//  Created by 渡邉凌 on 2021/01/17.
//
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import PKHUD

class SignUpViewController: UIViewController{
    
    @IBOutlet weak var profileImageButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var alreadyHaveAccountButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.isHidden = true
    }
    private func setupViews(){
        
        profileImageButton.layer.cornerRadius = 85
        profileImageButton.layer.borderWidth = 1
        profileImageButton.layer.borderColor = UIColor.rgb(red: 240, green: 240, blue: 240).cgColor
        registerButton.layer.cornerRadius = 12
        alreadyHaveAccountButton.addTarget(self, action: #selector(tappedAlreadyHaveAccountButton), for: .touchUpInside)
        emailTextField.delegate = self
        passwordTextField.delegate = self
        usernameTextField.delegate = self
        registerButton.isEnabled = false
        registerButton.backgroundColor = UIColor.rgb(red: 100, green: 100, blue: 100)
        
    }
    
    @objc private func tappedAlreadyHaveAccountButton(){
        
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
        self.navigationController?.pushViewController(loginViewController, animated: true)
    }
    @IBAction func tappedProfileImageButton(_ sender: Any) {
        
        print("tappedprofileImageButton")
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func tappedregisterButton(_ sender: Any) {
        
        let image = profileImageButton.imageView?.image ?? UIImage(named: "defaultIcon")
        guard let uploadImage = image?.jpegData(compressionQuality: 0.3) else { return }
        HUD.show(.progress)
        let filename = NSUUID().uuidString
        let storageRef = Storage.storage().reference().child("profile_image").child(filename)
        storageRef.putData(uploadImage, metadata: nil){ (metadata, err) in
            if let err = err{
                print("Firestorageへの情報の保存に失敗しました。\(err)")
                HUD.hide()
                return
            }
            print("Firestorageへの情報の保存に成功しました。")
            
            storageRef.downloadURL { (url, err) in
                if let err = err{
                    print("Firestorageからのダウンロードに失敗しました。\(err)")
                    HUD.hide()
                    
                    return
                }
                guard let urlString = url?.absoluteString else { return }
                print("urlString: ",urlString)
                self.createUserToFirestore(profileImageUrl: urlString)
            }
        }
    }
    
    private func createUserToFirestore(profileImageUrl: String){
        print("tappedregisterButton")
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        Auth.auth().createUser(withEmail: email, password: password) { (res, err) in
            if let err = err{
                print("認証情報の取得に失敗しました。\(err)")
                HUD.hide()
                
                return
            }
            print("認証情報の取得に成功しました。")
            
            guard let uid = res?.user.uid else { return }
            guard let username = self.usernameTextField.text else { return }
            let docData = [
                "email": email,
                "username": username,
                "createdAt": Timestamp(),
                "profileImageUrl": profileImageUrl
            ] as [String : Any]
            
            Firestore.firestore().collection("users").document(uid).setData(docData){(err) in
                if let err = err{
                    print("firestoreへの保存に失敗しました。\(err)")
                    HUD.hide()
                    
                    return
                }
                print("firestoreへの保存に成功しました。")
                HUD.hide()
                
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension SignUpViewController: UITextFieldDelegate{
    func textFieldDidChangeSelection(_ textField: UITextField) {
        //        print("textField.text: ", textField.text)
        let emailIsEnpty = emailTextField.text?.isEmpty ?? false
        let passwordIsEnpty = passwordTextField.text?.isEmpty ?? false
        let usernameIsEnpty = usernameTextField.text?.isEmpty ?? false
        
        if emailIsEnpty || passwordIsEnpty || usernameIsEnpty{
            registerButton.isEnabled = false
            registerButton.backgroundColor = UIColor.rgb(red: 100, green: 100, blue: 100)
        }else{
            registerButton.isEnabled = true
            registerButton.backgroundColor = UIColor.rgb(red: 0, green: 185, blue: 0)
        }
    }
}

extension SignUpViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo
                                info: [UIImagePickerController.InfoKey : Any]) {
        if let editImage = info[.editedImage] as? UIImage{
            profileImageButton.setImage(editImage.withRenderingMode(.alwaysOriginal), for: .normal)
        } else if let originalImage = info[.originalImage] as? UIImage{
            profileImageButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        profileImageButton.setTitle("", for: .normal)
        profileImageButton.imageView?.contentMode = .scaleAspectFill
        profileImageButton.contentHorizontalAlignment = .fill
        profileImageButton.contentVerticalAlignment = .fill
        profileImageButton.clipsToBounds = true
        dismiss(animated: true, completion: nil)
    }
}
