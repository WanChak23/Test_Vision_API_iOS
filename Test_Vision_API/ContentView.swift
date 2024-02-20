//
//  ContentView.swift
//  Test_Vision_API
//
//  Created by Edwin on 11/2/2024.
//

import SwiftUI

struct ContentView: View {
    
    @State private var overlayPoints: [CGPoint] = []
    @State private var isTappedTogether = false
    
    var CameraViewFinder : some View{
         CameraView {   points in
             overlayPoints = points
             isTappedTogether = detectTapGesture(points: points)  }
             .overlay(FingersOverlay(with: overlayPoints)
                 .foregroundColor(isTappedTogether ? .red : .green)
             )
             .ignoresSafeArea()
         
     }
    
    var body: some View {
    
        
        ZStack{
            CameraViewFinder
        }
        
    }
}


struct FingersOverlay: Shape {
    let points: [CGPoint]

    private var pointsPath: UIBezierPath {
        let path = UIBezierPath()
        for point in points {
            path.move(to: point)
            path.addArc(withCenter: point, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        }
        return path
    }

    init(with points: [CGPoint]) {
        self.points = points
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addPath(Path(pointsPath.cgPath))
        return path
    }
}

func detectTapGesture(points: [CGPoint]) -> Bool {
    // Assuming the thumb and index fingers are the first two points in the array
    guard points.count >= 2 else {
        return false
    }
    
    let thumb = points[0]
    let indexFinger = points[1]
    
    // Define a threshold distance for tap detection
    let thresholdDistance: CGFloat = 18
    
    // Calculate the distance between thumb and index finger
    let distance = sqrt(pow(thumb.x - indexFinger.x, 2) + pow(thumb.y - indexFinger.y, 2))
    
    // Return true if the distance is less than the threshold
    return distance < thresholdDistance
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
