//
//  AngleCalculator.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 01/05/2026.
//

import Foundation
import CoreGraphics
import Vision

struct AngleCalculator {

    // Calculate angle at joint B formed by points A-B-C
    static func angle(
        pointA: CGPoint,
        pointB: CGPoint,
        pointC: CGPoint
    ) -> Double {
        let vectorBA = CGPoint(
            x: pointA.x - pointB.x,
            y: pointA.y - pointB.y
        )
        let vectorBC = CGPoint(
            x: pointC.x - pointB.x,
            y: pointC.y - pointB.y
        )

        let dotProduct = vectorBA.x * vectorBC.x + vectorBA.y * vectorBC.y
        let magnitudeBA = sqrt(vectorBA.x * vectorBA.x + vectorBA.y * vectorBA.y)
        let magnitudeBC = sqrt(vectorBC.x * vectorBC.x + vectorBC.y * vectorBC.y)

        guard magnitudeBA > 0, magnitudeBC > 0 else { return 0 }

        let cosAngle = dotProduct / (magnitudeBA * magnitudeBC)
        let clampedCos = max(-1.0, min(1.0, Double(cosAngle)))
        return acos(clampedCos) * (180.0 / .pi)
    }

    // Calculate vertical deviation of a point from a reference x
    static func verticalDeviation(
        point: CGPoint,
        referenceX: CGFloat
    ) -> Double {
        return Double(abs(point.x - referenceX))
    }

    // Calculate horizontal difference between two points (symmetry)
    static func horizontalDifference(
        pointA: CGPoint,
        pointB: CGPoint
    ) -> Double {
        return Double(abs(pointA.y - pointB.y))
    }

    // Calculate distance between two points
    static func distance(
        from pointA: CGPoint,
        to pointB: CGPoint
    ) -> Double {
        let dx = pointA.x - pointB.x
        let dy = pointA.y - pointB.y
        return Double(sqrt(dx * dx + dy * dy))
    }
}
