//
//  CameraView.swift
//  Test_Vision_API
//
//  Created by Edwin on 11/2/2024.
//

import SwiftUI

struct CameraView: UIViewControllerRepresentable{
    
    var pointsProcessorHandler: (([CGPoint]) -> Void)?
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let cvc = CameraViewController()
        cvc.pointsProcessorHandler = pointsProcessorHandler
        return cvc
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        //Not needed for this app
    }
}
