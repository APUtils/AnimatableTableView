//
//  ViewController.swift
//  AnimatableTableView-Example
//
//  Created by Anton Plebanovich on 01/12/2020.
//  Copyright © 2020 Anton Plebanovich. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {
    
    // ******************************* MARK: - @IBOutlets
    
    // ******************************* MARK: - Initialization and Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    // ******************************* MARK: - Actions
    
    @IBAction private func onAnimatableTableViewTap(_ sender: Any) {
        let vc = AnimatableTableViewVC.instantiateFromStoryboard()
        navigationController?.pushViewController(vc)
    }
}
