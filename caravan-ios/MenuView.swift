//
//  MenuView.swift
//  caravan-ios
//
//  Created by Sara Edmonds on 5/16/17.
//  Copyright © 2017 Nancy. All rights reserved.
//

import UIKit

class MenuView: UIView {

    private var delegate: MenuViewDelegate?
    
    convenience init(frame: CGRect, delegate: MenuViewDelegate) {
        self.init(frame: frame)
        
        self.delegate = delegate
        
        self.backgroundColor = UIColor.white
        
        let versionLabel = UILabel(frame: CGRect(x: 0, y:75, width: self.frame.width, height: 25))
        versionLabel.text = "v0.1.0"
        versionLabel.textAlignment = .center
        self.addSubview(versionLabel)
        
        let logoutButton = UIButton(frame: CGRect(x: 0, y: 125, width: self.frame.width, height: 100))
        logoutButton.backgroundColor = UIColor(colorLiteralRed: 99.0/255.0, green: 174/255.0, blue: 245.0/255.0, alpha: 1.0)
        logoutButton.setTitle("Logout", for: .normal)
        
        logoutButton.addTarget(self, action: #selector(self.didClickOnLogoutButton), for: UIControlEvents.touchUpInside)
        
        self.addSubview(logoutButton)
    }
    
    func didClickOnLogoutButton() {
        delegate?.didClickOnLogout()
    }
    
    override private init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
