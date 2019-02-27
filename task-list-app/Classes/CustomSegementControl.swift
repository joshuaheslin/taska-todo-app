//
//  CustomSegementControl.swift
//  task-list-app
//
//  Created by Joshua Heslin on 7/5/18.
//  Copyright © 2018 Joshua Heslin. All rights reserved.
//

import UIKit

@IBDesignable
class CustomSegementControl: UIControl {

    var buttons: [UIButton] = []
    var selector: UIView!
    var selectedSegementIndex = 0
    
    @IBInspectable
    var borderWidth: CGFloat = 0 {
        didSet{
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable
    var borderColor: UIColor = UIColor.clear {
        didSet{
            layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable
    var commaSeparatedButtonTitles: String = "" {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable
    var textColour: UIColor = UIColor.darkGray {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable
    var selectorColour: UIColor = UIColor.black {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable
    var selectorTextColour: UIColor = UIColor.white {
        didSet {
            updateView()
        }
    }
    
    
    
    func updateView() {
        buttons.removeAll()
        subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        
        let buttonTitles = commaSeparatedButtonTitles.components(separatedBy: ",")
        
        for buttonTitle in buttonTitles {
            let button = UIButton(type: .system)
            button.setTitle(buttonTitle, for: .normal)
            button.titleLabel?.font = UIFont(name: "Futura-Bold", size: 17.0)
            button.setTitleColor(textColour, for: .normal)
            button.addTarget(self, action: #selector(buttonTapped(button:)), for: .touchUpInside)
            buttons.append(button)
        }
        
        buttons[0].setTitleColor(selectorTextColour, for: .normal)
        
        let selectorWidth = Int(frame.width) / buttonTitles.count
        let selectorHeight = Int(frame.height)
        selector = UIView(frame: CGRect(x: 0, y: 0, width: selectorWidth, height: selectorHeight))
        selector.layer.cornerRadius = frame.height/2
        selector.backgroundColor = selectorColour
        addSubview(selector)
        
        let sv = UIStackView(arrangedSubviews: buttons)
        sv.axis = .horizontal
        sv.alignment = .fill
        sv.distribution = .fillProportionally
        addSubview(sv)
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        sv.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        sv.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        sv.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        
    }
    
    override func draw(_ rect: CGRect) {
        layer.cornerRadius = frame.height/2
    }
    
    @objc func buttonTapped(button: UIButton) {
        for (buttonIndex, btn) in buttons.enumerated() {
            btn.setTitleColor(textColour, for: .normal)
            
            if btn == button {
                selectedSegementIndex = buttonIndex
                
                let selectorStartPosition = frame.width / CGFloat(buttons.count) * CGFloat(buttonIndex)
                UIView.animate(withDuration: 0.3, animations: {
                    self.selector.frame.origin.x = selectorStartPosition
                    
                })
                btn.setTitleColor(selectorTextColour, for: .normal)
            }
        }
        sendActions(for: .valueChanged)
    }

}
