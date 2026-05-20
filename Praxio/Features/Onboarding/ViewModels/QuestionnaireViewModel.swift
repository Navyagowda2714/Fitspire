//
//  QuestionnaireViewModel.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 07/05/2026.
//


import Foundation
import Combine

enum QuestionnaireStep: Int, CaseIterable {
    case welcome       = 0
    case basicInfo     = 1
    case parqSafety    = 2
    case healthCheck   = 3
    case fitnessLevel  = 4
    case selfTests     = 5
    case goals         = 6
    case preferences   = 7
    case equipment     = 8
    case summary       = 9
}

@MainActor
final class QuestionnaireViewModel: ObservableObject {
    @Published var currentStep: QuestionnaireStep = .welcome
    @Published var response = QuestionnaireResponse()
    @Published var isComplete: Bool = false
    @Published var generatedPlan: GeneratedWorkoutPlan?
    @Published var isGenerating: Bool = false

    private let planEngine = PersonalizedPlanEngine()

    var totalSteps: Int { QuestionnaireStep.allCases.count }
    var progress: Double {
        Double(currentStep.rawValue) / Double(totalSteps - 1)
    }

    var canProceed: Bool {
        switch currentStep {
        case .welcome:      return !response.name.trimmingCharacters(in: .whitespaces).isEmpty  // must enter name first
        case .basicInfo:    return true  // all fields have defaults; no blocking needed
        case .parqSafety:   return true
        case .healthCheck:  return true
        case .fitnessLevel: return true
        case .selfTests:    return true
        case .goals:        return true
        case .preferences:  return true
        case .equipment:    return true
        case .summary:      return true
        }
    }

    func nextStep() {
        guard canProceed else { return }
        let nextRaw = currentStep.rawValue + 1
        if nextRaw < totalSteps {
            if let next = QuestionnaireStep(rawValue: nextRaw) {
                currentStep = next
            }
        } else {
            generatePlan()
        }
    }

    func previousStep() {
        let prevRaw = currentStep.rawValue - 1
        if prevRaw >= 0 {
            if let prev = QuestionnaireStep(rawValue: prevRaw) {
                currentStep = prev
            }
        }
    }

    func generatePlan() {
        isGenerating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self else { return }
            self.generatedPlan = self.planEngine.generate(from: self.response)
            self.isGenerating = false
            // Persist gender so exercise demo shows correct body diagram
            UserDefaults.standard.set(self.response.gender, forKey: "userGender")
            self.isComplete = true
        }
    }

    // PAR-Q helpers
    func parqAnswer(for key: String, value: Bool) {
        switch key {
        case "advised":     response.parqResult.advisedAgainstExercise = value
        case "chestActive": response.parqResult.chestPainDuringActivity = value
        case "chestRest":   response.parqResult.chestPainAtRest = value
        case "dizzy":       response.parqResult.dizzinessOrFainting = value
        case "joint":       response.parqResult.boneOrJointIssue = value
        case "medication":  response.parqResult.medicationsForHeartOrBP = value
        case "other":       response.parqResult.otherReasonNotToExercise = value
        default: break
        }
    }

    func toggleCondition(_ condition: CommonCondition) {
        if condition == .none {
            response.conditions = [.none]
            return
        }
        response.conditions.removeAll { $0 == .none }
        if response.conditions.contains(condition) {
            response.conditions.removeAll { $0 == condition }
            if response.conditions.isEmpty {
                response.conditions = [.none]
            }
        } else {
            response.conditions.append(condition)
        }
    }

    func toggleEquipment(_ item: HomeEquipment) {
        if item == .noEquipment {
            response.equipment = [.noEquipment]
            return
        }
        response.equipment.removeAll { $0 == .noEquipment }
        if response.equipment.contains(item) {
            response.equipment.removeAll { $0 == item }
            if response.equipment.isEmpty {
                response.equipment = [.noEquipment]
            }
        } else {
            response.equipment.append(item)
        }
    }
}
