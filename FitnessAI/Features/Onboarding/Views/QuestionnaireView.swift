//
//  QuestionnaireView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 07/05/2026.
//
//
//  QuestionnaireView.swift
//  FitnessAI
//
//  BUG FIX: After the Summary page, isComplete fires but only markProfileComplete()
//  was called — hasCompletedGoal remained false so AppRouter kept showing QuestionnaireView.
//  Also QuestionnaireCompleteView was never shown.
//  FIX: Added @State showComplete, a fullScreenCover for QuestionnaireCompleteView,
//  and the onContinue closure now calls BOTH markProfileComplete() AND markGoalComplete().
//

import SwiftUI

struct QuestionnaireView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = QuestionnaireViewModel()

    @State private var weightInLB  = false
    @State private var heightInFT  = false
    @State private var showComplete = false   // drives the completion sheet

    // FocusState — tracks which numeric field is active so we can show a
    // keyboard toolbar "Done" button. Without this the Continue button
    // is buried under the keyboard on the basicInfo step.
    enum Field: Hashable { case age, weight, height, name }
    @FocusState private var focusedField: Field?

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.appBG3).frame(height: 3)
                        Rectangle()
                            .fill(Color.appCyan)
                            .frame(width: geo.size.width * viewModel.progress, height: 3)
                            .animation(.easeInOut, value: viewModel.progress)
                    }
                }.frame(height: 3)

                // Back button
                if viewModel.currentStep != .welcome {
                    HStack {
                        Button { viewModel.previousStep() } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left").font(.system(size: 14, weight: .medium))
                                Text("Back").font(.system(size: 15))
                            }.foregroundStyle(Color.appT3)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 28).padding(.top, 16)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        stepContent
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, viewModel.currentStep == .welcome ? 40 : 20)
                    .padding(.bottom, 120)
                }
                .scrollDismissesKeyboard(.interactively)  // drag-to-dismiss keyboard
                .toolbar {
                    // "Done" button in keyboard toolbar — dismisses keyboard so
                    // the Continue button (now in .safeAreaInset) becomes tappable
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { focusedField = nil }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.appCyan)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }  // ← KEY FIX: moves above keyboard
        // ── BUG FIX ───────────────────────────────────────────────────────────────
        // OLD: .onChange(of: viewModel.isComplete) { _, complete in
        //          if complete { appState.markProfileComplete() }
        //      }
        // ↳ That only set hasCompletedProfile; hasCompletedGoal stayed false, so
        //   AppRouter kept routing back to QuestionnaireView forever.
        //
        // NEW: show QuestionnaireCompleteView; its onContinue sets BOTH flags.
        .onChange(of: viewModel.isComplete) { _, complete in
            if complete { showComplete = true }
        }
        .fullScreenCover(isPresented: $showComplete) {
            QuestionnaireCompleteView(
                plan: viewModel.generatedPlan,
                response: viewModel.response
            ) {
                // Must set both — AppRouter requires hasCompletedProfile AND hasCompletedGoal
                appState.markProfileComplete()
                appState.markGoalComplete(goal: fitnessGoal(from: viewModel.response.primaryGoal))
            }
        }
        // ─────────────────────────────────────────────────────────────────────────
    }

    // MARK: - WorkoutGoal → FitnessGoal mapping
    private func fitnessGoal(from goal: WorkoutGoal) -> FitnessGoal {
        switch goal {
        case .loseFat:        return .leanBody
        case .buildStrength:  return .muscleBuilding
        case .toneUp:         return .stayingLean
        case .improveHealth:  return .stayingActive
        case .buildMuscle:    return .bulking
        case .increaseEnergy: return .enduranceFitness
        }
    }

    // MARK: - Step router
    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .welcome:      welcomeStep
        case .basicInfo:    basicInfoStep
        case .parqSafety:   parqStep
        case .healthCheck:  healthCheckStep
        case .fitnessLevel: fitnessLevelStep
        case .selfTests:    selfTestsStep
        case .goals:        goalsStep
        case .preferences:  preferencesStep
        case .equipment:    equipmentStep
        case .summary:      summaryStep
        }
    }

    // MARK: - Title helper
    private func questionTitle(kicker: String, question: String, highlight: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(kicker).font(.system(size: 14)).foregroundStyle(Color.appT3)
            if let range = question.range(of: highlight) {
                let before = String(question[question.startIndex..<range.lowerBound])
                let after  = String(question[range.upperBound...])
                Text("\(before)\(Text(highlight).foregroundStyle(Color.appCyan))\(after)")
                    .font(.system(size: 28, weight: .bold)).foregroundStyle(.white)
            } else {
                Text(question).font(.system(size: 28, weight: .bold)).foregroundStyle(.white)
            }
        }
    }

    // MARK: - STEP 0: Welcome
    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            questionTitle(kicker: "You won't sweat it alone!",
                          question: "What's your name?", highlight: "name?")
            TextField("e.g. Alex", text: $viewModel.response.name)
                .font(.system(size: 20, weight: .semibold)).foregroundStyle(.white).tint(Color.appCyan)
                .frame(maxWidth: .infinity).frame(height: 54).padding(.horizontal, 16)
                .background(Color.appBG2).clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appCyan.opacity(0.4), lineWidth: 1))
        }
    }

    // MARK: - STEP 1: Basic info
    private var basicInfoStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            questionTitle(kicker: "Let's set your baseline!",
                          question: "Tell us about yourself", highlight: "yourself")
            fieldLabel("AGE")
            HStack {
                TextField("25", value: $viewModel.response.age, format: .number)
                    .keyboardType(.numberPad).tint(Color.appCyan)
                    .font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 54).padding(.horizontal, 16)
                    .background(Color.appBG2).clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appCyan.opacity(0.4), lineWidth: 1))
                    .focused($focusedField, equals: .age)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }
                Text("years").foregroundStyle(Color.appT3).font(.system(size: 14))
            }
            fieldLabel("WEIGHT")
            HStack(spacing: 12) {
                TextField(weightInLB ? "143" : "65",
                          value: Binding(
                            get: { weightInLB ? viewModel.response.weightKG * 2.20462 : viewModel.response.weightKG },
                            set: { newVal in viewModel.response.weightKG = weightInLB ? newVal / 2.20462 : newVal }
                          ), format: .number)
                    .keyboardType(.decimalPad).tint(Color.appCyan)
                    .font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 54).padding(.horizontal, 16)
                    .background(Color.appBG2).clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appCyan.opacity(0.4), lineWidth: 1))
                unitToggle(a: "KG", b: "LB", isB: $weightInLB)
            }
            fieldLabel("HEIGHT")
            HStack(spacing: 12) {
                TextField(heightInFT ? "5.4" : "165",
                          value: Binding(
                            get: { heightInFT ? viewModel.response.heightCM / 30.48 : viewModel.response.heightCM },
                            set: { newVal in viewModel.response.heightCM = heightInFT ? newVal * 30.48 : newVal }
                          ), format: .number)
                    .keyboardType(.decimalPad).tint(Color.appCyan)
                    .font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 54).padding(.horizontal, 16)
                    .background(Color.appBG2).clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appCyan.opacity(0.4), lineWidth: 1))
                unitToggle(a: "CM", b: "FT", isB: $heightInFT)
            }
            fieldLabel("GENDER")
            HStack(spacing: 10) {
                ForEach(["Female", "Male", "Other"], id: \.self) { g in
                    Button { viewModel.response.gender = g } label: {
                        Text(g).font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(viewModel.response.gender == g ? .black : .white)
                            .frame(maxWidth: .infinity).frame(height: 46)
                            .background(viewModel.response.gender == g ? Color.appCyan : Color.appBG2)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.response.gender == g ? Color.appCyan : Color.appHair, lineWidth: 1))
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - STEP 2: PAR-Q
    private var parqStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            questionTitle(kicker: "Safety first — takes 30 seconds",
                          question: "Health & safety check", highlight: "safety check")
            let questions: [(key: String, text: String)] = [
                ("advised",     "Has a doctor ever advised you not to exercise?"),
                ("chestActive", "Do you feel chest pain during physical activity?"),
                ("chestRest",   "Do you feel chest pain when at rest?"),
                ("dizzy",       "Do you lose balance due to dizziness or faint?"),
                ("joint",       "Do you have a bone or joint problem?"),
                ("medication",  "Are you on medication for heart or blood pressure?"),
                ("other",       "Any other reason you should not exercise?")
            ]
            VStack(spacing: 10) {
                ForEach(questions, id: \.key) { q in
                    let val = parqBool(for: q.key)
                    HStack(spacing: 12) {
                        Text(q.text).font(.system(size: 13)).foregroundStyle(Color.appT2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack(spacing: 6) {
                            parqButton("Yes", active: val == true)  { viewModel.parqAnswer(for: q.key, value: true)  }
                            parqButton("No",  active: val == false) { viewModel.parqAnswer(for: q.key, value: false) }
                        }
                    }
                    .padding(12).background(Color.appBG2)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.appHair, lineWidth: 0.5))
                }
            }
            if viewModel.response.parqResult.requiresMedicalClearance {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color.appWarn)
                    Text("We recommend medical clearance before starting. You can still proceed.")
                        .font(.system(size: 12)).foregroundStyle(Color.appT2)
                }
                .padding(12).background(Color.appWarn.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appWarn.opacity(0.3), lineWidth: 1))
            }
        }
    }

    // MARK: - STEP 3: Health conditions
    private var healthCheckStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            questionTitle(kicker: "We'll adapt your plan around this",
                          question: "Any injuries or conditions?", highlight: "conditions?")
            VStack(spacing: 8) {
                ForEach(CommonCondition.allCases, id: \.self) { condition in
                    let selected = viewModel.response.conditions.contains(condition)
                    Button { viewModel.toggleCondition(condition) } label: {
                        HStack(spacing: 14) {
                            Text(condition.rawValue).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                            Spacer()
                            checkboxView(selected: selected)
                        }
                        .padding(14).background(selected ? Color.appCyan.opacity(0.08) : Color.appBG2)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selected ? Color.appCyan.opacity(0.5) : Color.appHair, lineWidth: 1))
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - STEP 4: Fitness level
    private var fitnessLevelStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            questionTitle(kicker: "Be honest — we calibrate to you!",
                          question: "What's your experience level?", highlight: "experience level?")
            VStack(spacing: 10) {
                ForEach(ExperienceLevel.allCases, id: \.rawValue) { level in
                    let selected = viewModel.response.experience == level
                    Button { viewModel.response.experience = level } label: {
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(level.rawValue).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                                Text(levelDescription(level)).font(.system(size: 12)).foregroundStyle(Color.appT3)
                            }
                            Spacer()
                            radioView(selected: selected)
                        }
                        .padding(14).background(selected ? Color.appCyan.opacity(0.08) : Color.appBG2)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selected ? Color.appCyan.opacity(0.5) : Color.appHair, lineWidth: 1))
                    }.buttonStyle(.plain)
                }
            }
            fieldLabel("CURRENTLY ACTIVE")
            HStack(spacing: 8) {
                ForEach([1, 2, 3, 4, 5, 6, 7], id: \.self) { days in
                    Button { viewModel.response.activeDaysPerWeek = days } label: {
                        Text("\(days)").font(.system(size: 15, weight: .bold))
                            .foregroundStyle(viewModel.response.activeDaysPerWeek == days ? .black : .white)
                            .frame(maxWidth: .infinity).frame(height: 44)
                            .background(viewModel.response.activeDaysPerWeek == days ? Color.appCyan : Color.appBG2)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(viewModel.response.activeDaysPerWeek == days ? Color.appCyan : Color.appHair, lineWidth: 1))
                    }.buttonStyle(.plain)
                }
            }
            Text("days per week").font(.system(size: 12)).foregroundStyle(Color.appT3)
        }
    }

    // MARK: - STEP 5: Self tests
    private var selfTestsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            questionTitle(kicker: "Optional but super useful",
                          question: "Quick fitness self-test", highlight: "self-test")
            stepperField(label: "MAX PUSH-UPS", value: $viewModel.response.selfTest.maxPushUps,
                         subtitle: "How many can you do without stopping?")
            stepperField(label: "PLANK HOLD (SECONDS)", value: $viewModel.response.selfTest.plankHoldSeconds,
                         subtitle: "How many seconds can you hold a plank?")
            Button {
                viewModel.response.selfTest.didSkipTests = true
                viewModel.nextStep()
            } label: {
                Text("Skip — use my experience level").font(.system(size: 14)).foregroundStyle(Color.appT3)
                    .frame(maxWidth: .infinity).frame(height: 44).background(Color.appBG2)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appHair, lineWidth: 0.5))
            }.buttonStyle(.plain)
        }
    }

    // MARK: - STEP 6: Goals
    private var goalsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            questionTitle(kicker: "This shapes your entire plan",
                          question: "What's your primary goal?", highlight: "primary goal?")
            VStack(spacing: 8) {
                ForEach(WorkoutGoal.allCases, id: \.rawValue) { goal in
                    let selected = viewModel.response.primaryGoal == goal
                    Button { viewModel.response.primaryGoal = goal } label: {
                        HStack(spacing: 14) {
                            Image(systemName: goal.icon).font(.system(size: 18))
                                .foregroundStyle(selected ? Color.appCyan : Color.appT3).frame(width: 28)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(goal.rawValue).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                                Text(goal.description).font(.system(size: 12)).foregroundStyle(Color.appT3)
                            }
                            Spacer()
                            radioView(selected: selected)
                        }
                        .padding(14).background(selected ? Color.appCyan.opacity(0.08) : Color.appBG2)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selected ? Color.appCyan.opacity(0.5) : Color.appHair, lineWidth: 1))
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - STEP 7: Preferences
    private var preferencesStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            questionTitle(kicker: "Customise your sessions",
                          question: "Training preferences", highlight: "preferences")
            fieldLabel("FOCUS AREA")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(FocusArea.allCases, id: \.rawValue) { area in
                    let sel = viewModel.response.focusArea == area
                    Button { viewModel.response.focusArea = area } label: {
                        VStack(spacing: 4) {
                            Text(area.rawValue).font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(sel ? .black : .white)
                            Text(area.muscles).font(.system(size: 10))
                                .foregroundStyle(sel ? Color.black.opacity(0.6) : Color.appT4)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(sel ? Color.appCyan : Color.appBG2)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(sel ? Color.appCyan : Color.appHair, lineWidth: 1))
                    }.buttonStyle(.plain)
                }
            }
            fieldLabel("SESSION LENGTH")
            HStack(spacing: 8) {
                ForEach(SessionLength.allCases, id: \.rawValue) { length in
                    let sel = viewModel.response.sessionLength == length
                    Button { viewModel.response.sessionLength = length } label: {
                        Text(length.rawValue).font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(sel ? .black : .white)
                            .frame(maxWidth: .infinity).frame(height: 46)
                            .background(sel ? Color.appCyan : Color.appBG2)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(sel ? Color.appCyan : Color.appHair, lineWidth: 1))
                    }.buttonStyle(.plain)
                }
            }
            fieldLabel("DAYS PER WEEK")
            HStack(spacing: 10) {
                ForEach(TrainingDays.allCases, id: \.rawValue) { option in
                    let sel = viewModel.response.trainingDays == option
                    Button { viewModel.response.trainingDays = option } label: {
                        VStack(spacing: 3) {
                            Text("\(option.rawValue)").font(.system(size: 22, weight: .bold))
                                .foregroundStyle(sel ? .black : .white)
                            Text("days").font(.system(size: 11))
                                .foregroundStyle(sel ? Color.black.opacity(0.6) : Color.appT3)
                        }
                        .frame(maxWidth: .infinity).frame(height: 70)
                        .background(sel ? Color.appCyan : Color.appBG2)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(sel ? Color.appCyan : Color.appHair, lineWidth: 1))
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - STEP 8: Equipment
    private var equipmentStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            questionTitle(kicker: "We'll build around what you have",
                          question: "Select your equipment", highlight: "equipment")
            VStack(spacing: 8) {
                ForEach(HomeEquipment.allCases) { item in
                    let selected = viewModel.response.equipment.contains(item)
                    Button { viewModel.toggleEquipment(item) } label: {
                        HStack(spacing: 14) {
                            Text(item.displayName).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                            Spacer()
                            checkboxView(selected: selected)
                        }
                        .padding(14).background(selected ? Color.appCyan.opacity(0.08) : Color.appBG2)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selected ? Color.appCyan.opacity(0.5) : Color.appHair, lineWidth: 1))
                    }.buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.15), value: selected)
                }
            }
        }
    }

    // MARK: - STEP 9: Summary
    private var summaryStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            questionTitle(kicker: "Almost done!", question: "Here's your summary", highlight: "your summary")
            VStack(spacing: 10) {
                summaryRow(label: "Name",     value: viewModel.response.name)
                summaryRow(label: "Age",      value: "\(viewModel.response.age) years")
                summaryRow(label: "Weight",   value: String(format: "%.1f kg", viewModel.response.weightKG))
                summaryRow(label: "Height",   value: String(format: "%.0f cm", viewModel.response.heightCM))
                summaryRow(label: "Goal",     value: viewModel.response.primaryGoal.rawValue)
                summaryRow(label: "Focus",    value: viewModel.response.focusArea.rawValue)
                summaryRow(label: "Sessions", value: "\(viewModel.response.trainingDays.rawValue)× \(viewModel.response.sessionLength.rawValue)")
                summaryRow(label: "Level",    value: viewModel.response.experience.rawValue)
            }
            if viewModel.isGenerating {
                HStack(spacing: 12) {
                    ProgressView().tint(Color.appCyan)
                    Text("Building your personalised plan…").font(.system(size: 14)).foregroundStyle(Color.appT2)
                }
                .frame(maxWidth: .infinity).padding(16).background(Color.appBG2)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Bottom bar
    private var bottomBar: some View {
        Button { viewModel.nextStep() } label: {
            HStack {
                Text(viewModel.currentStep == .summary ? "Generate my plan" : "Continue")
                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                Spacer()
                if viewModel.isGenerating {
                    ProgressView().tint(.white).scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.right").font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.appCyan)
                }
            }
            .padding(.horizontal, 28).frame(maxWidth: .infinity).frame(height: 58).background(Color.clear)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appCyan, lineWidth: 1.5))
        }
        .disabled(!viewModel.canProceed || viewModel.isGenerating)
        .opacity((!viewModel.canProceed && !viewModel.isGenerating) ? 0.4 : 1.0)  // visual disabled state
        .padding(.horizontal, 28).padding(.bottom, 44).padding(.top, 16)
        .background(LinearGradient(colors: [Color.appBG.opacity(0), Color.appBG],
                                    startPoint: .top, endPoint: .bottom))
    }

    // MARK: - Reusable sub-components (unchanged)
    private func fieldLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 11, weight: .bold)).kerning(1.2).foregroundStyle(Color.appCyan)
    }

    private func unitToggle(a: String, b: String, isB: Binding<Bool>) -> some View {
        HStack(spacing: 0) {
            Button { isB.wrappedValue = false } label: {
                Text(a).font(.system(size: 14, weight: .bold))
                    .foregroundStyle(!isB.wrappedValue ? .black : Color.appT3)
                    .frame(width: 48, height: 54)
                    .background(!isB.wrappedValue ? Color.appCyan : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }.buttonStyle(.plain)
            Button { isB.wrappedValue = true } label: {
                Text(b).font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isB.wrappedValue ? .black : Color.appT3)
                    .frame(width: 48, height: 54)
                    .background(isB.wrappedValue ? Color.appCyan : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }.buttonStyle(.plain)
        }
        .background(Color.appBG2).clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appHair2, lineWidth: 0.5))
        .animation(.easeInOut(duration: 0.15), value: isB.wrappedValue)
    }

    private func parqButton(_ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(size: 13, weight: .bold))
                .foregroundStyle(active ? .black : Color.appT3)
                .frame(width: 44, height: 32)
                .background(active ? Color.appCyan : Color.appBG3)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }.buttonStyle(.plain)
    }

    private func radioView(selected: Bool) -> some View {
        ZStack {
            Circle().stroke(selected ? Color.appCyan : Color.appHair2, lineWidth: 1.5).frame(width: 22, height: 22)
            if selected { Circle().fill(Color.appCyan).frame(width: 12, height: 12) }
        }
    }

    private func checkboxView(selected: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).stroke(selected ? Color.appCyan : Color.appHair2, lineWidth: 1.5)
                .frame(width: 22, height: 22)
            if selected {
                RoundedRectangle(cornerRadius: 4).fill(Color.appCyan).frame(width: 14, height: 14)
                Image(systemName: "checkmark").font(.system(size: 10, weight: .black)).foregroundStyle(.black)
            }
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundStyle(Color.appT3)
            Spacer()
            Text(value).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
        }
        .padding(.horizontal, 14).padding(.vertical, 10).background(Color.appBG2)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func stepperField(label: String, value: Binding<Int>, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(label)
            Text(subtitle).font(.system(size: 12)).foregroundStyle(Color.appT3)
            HStack(spacing: 16) {
                Button { if value.wrappedValue > 0 { value.wrappedValue -= 1 } } label: {
                    Image(systemName: "minus").font(.system(size: 18, weight: .bold)).foregroundStyle(Color.appCyan)
                        .frame(width: 44, height: 44).background(Color.appBG2)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appHair, lineWidth: 0.5))
                }.buttonStyle(.plain)
                Text("\(value.wrappedValue)").font(.system(size: 28, weight: .bold)).foregroundStyle(.white)
                    .monospacedDigit().frame(minWidth: 60, alignment: .center)
                Button { value.wrappedValue += 1 } label: {
                    Image(systemName: "plus").font(.system(size: 18, weight: .bold)).foregroundStyle(Color.appCyan)
                        .frame(width: 44, height: 44).background(Color.appBG2)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appHair, lineWidth: 0.5))
                }.buttonStyle(.plain)
            }
        }
        .padding(14).background(Color.appBG2).clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appHair, lineWidth: 0.5))
    }

    private func levelDescription(_ level: ExperienceLevel) -> String {
        switch level {
        case .beginner:     return "New to training or returning after a break"
        case .intermediate: return "Training consistently for 6+ months"
        case .advanced:     return "2+ years of structured training"
        }
    }

    private func parqBool(for key: String) -> Bool? {
        let r = viewModel.response.parqResult
        switch key {
        case "advised":     return r.advisedAgainstExercise     ? true : nil
        case "chestActive": return r.chestPainDuringActivity    ? true : nil
        case "chestRest":   return r.chestPainAtRest            ? true : nil
        case "dizzy":       return r.dizzinessOrFainting        ? true : nil
        case "joint":       return r.boneOrJointIssue           ? true : nil
        case "medication":  return r.medicationsForHeartOrBP    ? true : nil
        case "other":       return r.otherReasonNotToExercise   ? true : nil
        default:            return nil
        }
    }
}
