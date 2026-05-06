//
//  OnboardingViewModel.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import Foundation
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    let pages = OnboardingPage.all

    var isLastPage: Bool {
        currentPage == pages.count - 1
    }

    func nextPage() {
        if !isLastPage { currentPage += 1 }
    }
}
