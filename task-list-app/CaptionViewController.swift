//
//  CaptionViewController.swift
//  task-list-app
//
//  Created by Joshua Heslin on 22/5/18.
//  Copyright © 2018 Joshua Heslin. All rights reserved.
//

import UIKit

class CaptionViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var captionTextField: UITextField!
    
    let urlArray = ["https://static1.squarespace.com/static/57aad0acc534a54cc4bb263e/5b03eba188251b9e5e742c91/5b03eba26d2a735b9703f4c9/1526983593071/1adauc.jpg",
                    "https://static1.squarespace.com/static/57aad0acc534a54cc4bb263e/5b03eba188251b9e5e742c91/5b03eba4352f530afd575387/1526983596164/1s6cjm.jpg",
                    "https://static1.squarespace.com/static/57aad0acc534a54cc4bb263e/5b03eba188251b9e5e742c91/5b03eba9562fa7bfe331e03b/1526983595238/3kyx1.jpg",
                    "https://static1.squarespace.com/static/57aad0acc534a54cc4bb263e/5b03eba188251b9e5e742c91/5b03ebaaaa4a99b7ce27b532/1526983596186/8eux6.jpg",
                    "https://i.imgflip.com/1bgw.jpg"]
    
    var n = 0
    
    var urlArrayCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.hideKeyboardWhenTappedAround()
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.swiped(gesture:)))
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        self.view.addGestureRecognizer(swipeRight)
        
        urlArrayCount = urlArray.count
        
        let url = URL(string: urlArray[urlArrayCount-1])!
        
        imageView.load(url: url)
        
        captionTextField.delegate = self
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func share(_ sender: Any) {
        
        if captionTextField.text == "" {
            displayAlert(title: "oops.", message: "please enter a caption.")
        } else {
            if let caption = captionTextField.text {
                displayShareSheet(shareContent: caption)
            }
        }
        
    }
    

    func displayAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
        return
    }
    

    func displayShareSheet(shareContent:String) {
        
        if let image = imageView.image {
            let activityViewController = UIActivityViewController(activityItems: [shareContent as NSString, image ], applicationActivities: nil)
            present(activityViewController, animated: true, completion: {})
        } else {
            displayAlert(title: "pls wait.", message: "image has not loaded yet.")
        }
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        
        if n == urlArrayCount - 1 {
            n = 0
        } else {
            n += 1
        }
        
        let url = URL(string: urlArray[n])!

        print("url")
        
        imageView.load(url: url)
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                        print("set")
                    }
                    print("image")
                }
                print("data")
            }
        }
    }
}
