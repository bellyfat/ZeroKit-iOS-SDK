import UIKit
import ZeroKit

class SignInViewController: UIViewController {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: ZeroKitPasswordField!
    @IBOutlet weak var signInButton: UIButton!
    
    @IBAction func signInButtonTap(_ sender: AnyObject) {
        self.view.endEditing(true)
        
        guard let username = usernameTextField.text, !passwordTextField.isEmpty else {
            self.showAlert("Username and password must not be empty")
            return
        }
        
        AppDelegate.current.showProgress()
        
        AppDelegate.current.backend?.getUserId(forUsername: username) { userId, error in
            
            guard error == nil else {
                self.showAlert("Error getting user ID", message: "\(error!)")
                AppDelegate.current.hideProgress()
                return
            }
            
            AppDelegate.current.zeroKit?.login(withUserId: userId!, passwordField: self.passwordTextField, rememberMe: false) { error in
                AppDelegate.current.hideProgress()
                
                guard error == nil else {
                    self.showAlert("Sign in error", message: "\(error!)")
                    return
                }
                
                AppDelegate.current.showAfterSigninScreen()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
}
