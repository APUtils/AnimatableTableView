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
        let vm = AnimatableTableViewVM(useSizeControllers: false)
        let vc = AnimatableTableViewVC.instantiateFromStoryboard(vm: vm)
        navigationController?.pushViewController(vc)
    }
    
    @IBAction private func onAnimatableTableViewWithControllersTap(_ sender: Any) {
        let vm = AnimatableTableViewVM(useSizeControllers: true)
        let vc = AnimatableTableViewVC.instantiateFromStoryboard(vm: vm)
        navigationController?.pushViewController(vc)
    }
}
