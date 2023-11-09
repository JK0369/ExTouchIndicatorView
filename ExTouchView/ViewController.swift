//
//  ViewController.swift
//  ExTouchView
//
//  Created by 김종권 on 2023/11/09.
//

import UIKit

class ViewController: UIViewController {
    private let button = {
        let button = UIButton()
        button.setTitle("button", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.setTitleColor(.blue, for: .highlighted)
        button.addTarget(self, action: #selector(handleDidTapButton), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        self.view.backgroundColor = UIColor.white
    }
    
    @objc func handleDidTapButton() {
        print("tap!")
    }
}
