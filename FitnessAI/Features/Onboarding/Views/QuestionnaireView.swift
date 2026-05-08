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
//  Created by Navyashree Byregowda on 07/05/2026.
//


import SwiftUI

struct QuestionnaireView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = QuestionnaireViewModel()

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            if viewModel.isComplete {
                QuestionnaireCompleteView(
                    plan: viewModel.generatedPlan,
                    response: viewModel.response
                ) {
                    saveAndContinue()
                }
            } else if viewModel.isGenerating {
                generatingView
            } else {
                VStack(spacing: 0) {
                    progressBar
                    stepContent
                    navigationButtons
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Step \(viewModel.currentStep.rawValue + 1) of \(viewModel.totalSteps)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appT3)
                Spacer()
                Text("\(Int(viewModel.progress * 100))% complete")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appLime)
            }
            .padding(.horizontal, 24)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.appBG3)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.appLime)
                        .frame(
                            width: geo.size.width * viewModel.progress,
                            height: 4
                        )
                        .animation(.easeInOut(duration: 0.4), value: viewModel.progress)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 24)
        }
        .padding(.top, 56)
        .padding(.bottom, 20)
    }

    // MARK: - Step content

    @ViewBuilder
    private var stepContent: some View {
        ScrollView {
            switch viewModel.currentStep {
            case .welcome:      welcomeStep
            case .basicInfo:    basicInfoStep
            case .parqSafety:   parqStep
            case .healthCheck:  healthCheckStep
            case .fitnessLevel: fitnessLevelStep
            case .selfTests:    selfTestStep
            case .goals:        goalsStep
            case .preferences:  preferencesStep
            case .equipment:    equipmentStep
            case .summary:      summaryStep
            }
        }
    }

    // MARK: - Welcome

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Let us build your\nperfect plan")
                    .font(.system(size: 30, weight: .bold))
                    .lineSpacing(3)
                Text("Answer 10 quick questions and we will create a personalised home workout programme built around your body, goals, and equipment.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appT3)
                    .lineSpacing(4)
            }

            VStack(spacing: 12) {
                FeatureRow(icon: "shield.fill",       color: "1D9E75", text: "Safety first — PAR-Q health screening")
                FeatureRow(icon: "person.fill",       color: "C6FF3D", text: "Personalised to your fitness level")
                FeatureRow(icon: "house.fill",        color: "BA7517", text: "Designed for your home and equipment")
                FeatureRow(icon: "camera.viewfinder", color: "C6FF3D", text: "Real-time form correction via camera")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", color: "D85A30", text: "Progressive plans that adapt weekly")
            }
            .padding(16)
            .background(Color.appBG2)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("Takes about 3 minutes · No account required")
                .font(.system(size: 12))
                .foregroundStyle(Color.appT3)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Basic Info

    private var basicInfoStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Tell us about yourself",
                subtitle: "Used to calculate accurate calorie burn, workout intensity, and personalised progressions."
            )

            QTextField(label: "Your name", placeholder: "Alex",
                       text: Binding(get: { viewModel.response.name },
                                     set: { viewModel.response.name = $0 }))

            HStack(spacing: 12) {
                QNumberField(
                    label: "Age",
                    placeholder: "25",
                    value: Binding(
                        get: { "\(viewModel.response.age)" },
                        set: { viewModel.response.age = Int($0) ?? 25 }
                    )
                )
                VStack(alignment: .leading, spacing: 6) {
                    Text("Gender")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appT3)
                    HStack(spacing: 8) {
                        ForEach(["Female", "Male", "Other"], id: \.self) { g in
                            Button {
                                viewModel.response.gender = g
                            } label: {
                                Text(g)
                                    .font(.system(
                                        size: 12,
                                        weight: viewModel.response.gender == g ? .medium : .regular
                                    ))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(viewModel.response.gender == g
                                                ? Color.appLime.opacity(0.12)
                                                : Color.appBG2)
                                    .foregroundStyle(viewModel.response.gender == g
                                                     ? Color.appLime
                                                     : Color.secondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                QNumberField(
                    label: "Height (cm)",
                    placeholder: "165",
                    value: Binding(
                        get: { "\(Int(viewModel.response.heightCM))" },
                        set: { viewModel.response.heightCM = Double($0) ?? 165 }
                    )
                )
                QNumberField(
                    label: "Weight (kg)",
                    placeholder: "65",
                    value: Binding(
                        get: { "\(Int(viewModel.response.weightKG))" },
                        set: { viewModel.response.weightKG = Double($0) ?? 65 }
                    )
                )
            }

            QTextField(
                label: "Location (optional)",
                placeholder: "Naples, Italy",
                text: Binding(
                    get: { viewModel.response.location },
                    set: { viewModel.response.location = $0 }
                )
            )

            infoBox("Your height and weight help calculate ideal training volume. Location helps adapt routines to your climate.")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - PAR-Q

    private var parqStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Health and safety check",
                subtitle: "The Physical Activity Readiness Questionnaire (PAR-Q) ensures exercise is safe for you. Answer honestly."
            )

            warningBox("If you answer YES to any question, consult a doctor before starting any exercise programme.")

            VStack(spacing: 10) {
                PARQRow(
                    question: "Has a doctor ever said your heart requires you to avoid strenuous exercise?",
                    value: Binding(
                        get: { viewModel.response.parqResult.advisedAgainstExercise },
                        set: { viewModel.parqAnswer(for: "advised", value: $0) }
                    )
                )
                PARQRow(
                    question: "Do you experience chest pain, tightness, or discomfort during physical activity?",
                    value: Binding(
                        get: { viewModel.response.parqResult.chestPainDuringActivity },
                        set: { viewModel.parqAnswer(for: "chestActive", value: $0) }
                    )
                )
                PARQRow(
                    question: "In the past month, have you had chest pain or pressure when NOT being physically active?",
                    value: Binding(
                        get: { viewModel.response.parqResult.chestPainAtRest },
                        set: { viewModel.parqAnswer(for: "chestRest", value: $0) }
                    )
                )
                PARQRow(
                    question: "Do you ever feel faint, dizzy, or lose balance during or after exercise?",
                    value: Binding(
                        get: { viewModel.response.parqResult.dizzinessOrFainting },
                        set: { viewModel.parqAnswer(for: "dizzy", value: $0) }
                    )
                )
                PARQRow(
                    question: "Do you have a bone, joint, or muscle problem that could worsen with exercise?",
                    value: Binding(
                        get: { viewModel.response.parqResult.boneOrJointIssue },
                        set: { viewModel.parqAnswer(for: "joint", value: $0) }
                    )
                )
                PARQRow(
                    question: "Are you currently taking medication for blood pressure or a heart condition?",
                    value: Binding(
                        get: { viewModel.response.parqResult.medicationsForHeartOrBP },
                        set: { viewModel.parqAnswer(for: "medication", value: $0) }
                    )
                )
                PARQRow(
                    question: "Is there any other reason you should NOT participate in physical activity right now?",
                    value: Binding(
                        get: { viewModel.response.parqResult.otherReasonNotToExercise },
                        set: { viewModel.parqAnswer(for: "other", value: $0) }
                    )
                )
            }

            if viewModel.response.parqResult.requiresMedicalClearance {
                warningBox("You answered YES to one or more questions. We recommend consulting your doctor before starting. FitnessAI will still create a gentle programme for you.")
            } else {
                infoBox("✓ Great — you are cleared to exercise. Your plan will be built safely around your goals.")
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Health Check

    private var healthCheckStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Any injuries or conditions?",
                subtitle: "Select everything that applies. We will automatically remove unsafe exercises from your plan."
            )

            VStack(spacing: 8) {
                ForEach(CommonCondition.allCases, id: \.self) { condition in
                    Button {
                        viewModel.toggleCondition(condition)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: viewModel.response.conditions.contains(condition)
                                  ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundStyle(viewModel.response.conditions.contains(condition)
                                                 ? Color.appLime
                                                 : Color.secondary.opacity(0.4))
                            Text(condition.rawValue)
                                .font(.system(size: 15))
                                .foregroundStyle(Color.primary)
                            Spacer()
                        }
                        .padding(14)
                        .background(viewModel.response.conditions.contains(condition)
                                    ? Color.appLime.opacity(0.12)
                                    : Color.appBG2)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15),
                               value: viewModel.response.conditions.contains(condition))
                }
            }

            if !viewModel.response.conditions.contains(.none) {
                infoBox("Exercises will be automatically adapted to avoid aggravating these areas.")
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Fitness Level

    private var fitnessLevelStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Your fitness experience",
                subtitle: "Be honest — we build the plan around where you are now, not where you want to be."
            )

            VStack(spacing: 10) {
                ForEach(ExperienceLevel.allCases, id: \.self) { level in
                    Button {
                        viewModel.response.experience = level
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(viewModel.response.experience == level
                                          ? Color.appLime
                                          : Color.appBG3)
                                    .frame(width: 44, height: 44)
                                Image(systemName: levelIcon(level))
                                    .font(.system(size: 18))
                                    .foregroundStyle(viewModel.response.experience == level
                                                     ? .white : Color.secondary)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(level.rawValue)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.primary)
                                Text(levelDescription(level))
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.appT3)
                            }
                            Spacer()
                            if viewModel.response.experience == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.appLime)
                            }
                        }
                        .padding(14)
                        .background(viewModel.response.experience == level
                                    ? Color.appLime.opacity(0.12)
                                    : Color.appBG2)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.response.experience == level
                                    ? Color.appLime : Color.clear,
                                    lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            stepHeader(
                title: "How many days per week are you currently active?",
                subtitle: ""
            )

            HStack(spacing: 10) {
                ForEach(0...6, id: \.self) { day in
                    Button {
                        viewModel.response.activeDaysPerWeek = day
                    } label: {
                        Text("\(day)")
                            .font(.system(size: 15, weight: .medium))
                            .frame(width: 40, height: 40)
                            .background(viewModel.response.activeDaysPerWeek == day
                                        ? Color.appLime
                                        : Color.appBG2)
                            .foregroundStyle(viewModel.response.activeDaysPerWeek == day
                                             ? .white : Color.primary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Self Tests

    private var selfTestStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Optional fitness self-tests",
                subtitle: "These help us pinpoint your exact starting level. Skip if you prefer — we will use your experience level instead."
            )

            Button {
                viewModel.response.selfTest.didSkipTests = true
                viewModel.nextStep()
            } label: {
                Text("Skip these tests")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appLime)
            }

            VStack(spacing: 16) {
                SelfTestInput(
                    title: "Max push-ups in 60 seconds",
                    subtitle: "Full push-ups (or knee push-ups for beginners)",
                    icon: "figure.highintensity.intervaltraining",
                    unit: "reps",
                    value: Binding(
                        get: { viewModel.response.selfTest.maxPushUps },
                        set: { viewModel.response.selfTest.maxPushUps = $0 }
                    )
                )

                SelfTestInput(
                    title: "Plank hold time",
                    subtitle: "Hold a plank as long as you can with good form",
                    icon: "figure.core.training",
                    unit: "seconds",
                    value: Binding(
                        get: { viewModel.response.selfTest.plankHoldSeconds },
                        set: { viewModel.response.selfTest.plankHoldSeconds = $0 }
                    )
                )

                if viewModel.response.selfTest.maxPushUps > 0 ||
                   viewModel.response.selfTest.plankHoldSeconds > 0 {
                    let level = viewModel.response.computedFitnessLevel
                    infoBox("Based on your self-test, your fitness level is: **\(level.rawValue)**. Your plan will be built at this level.")
                }
            }

            stepHeader(
                title: "Motivation level",
                subtitle: "How motivated are you to commit to this programme right now?"
            )

            HStack(spacing: 0) {
                ForEach(1...10, id: \.self) { i in
                    Button {
                        viewModel.response.motivationLevel = i
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(i)")
                                .font(.system(size: 13, weight: .medium))
                                .frame(width: 30, height: 30)
                                .background(viewModel.response.motivationLevel >= i
                                            ? Color.appLime
                                            : Color.appBG2)
                                .foregroundStyle(viewModel.response.motivationLevel >= i
                                                 ? .white : Color.secondary)
                                .clipShape(Circle())
                        }
                    }
                    .buttonStyle(.plain)
                    if i < 10 { Spacer() }
                }
            }

            HStack {
                Text("Low")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appT3)
                Spacer()
                Text("Very motivated")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appT3)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Goals

    private var goalsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "What is your main goal?",
                subtitle: "This determines the type of training, rep ranges, and intensity of your plan."
            )

            VStack(spacing: 10) {
                ForEach(WorkoutGoal.allCases, id: \.self) { goal in
                    Button {
                        viewModel.response.primaryGoal = goal
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(viewModel.response.primaryGoal == goal
                                          ? Color.appLime
                                          : Color.appBG3)
                                    .frame(width: 40, height: 40)
                                Image(systemName: goal.icon)
                                    .font(.system(size: 17))
                                    .foregroundStyle(viewModel.response.primaryGoal == goal
                                                     ? .white : Color.secondary)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(goal.rawValue)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.primary)
                                Text(goal.description)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.appT3)
                            }
                            Spacer()
                            if viewModel.response.primaryGoal == goal {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.appLime)
                            }
                        }
                        .padding(14)
                        .background(viewModel.response.primaryGoal == goal
                                    ? Color.appLime.opacity(0.12)
                                    : Color.appBG2)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.response.primaryGoal == goal
                                    ? Color.appLime : Color.clear,
                                    lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Preferences

    private var preferencesStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            stepHeader(
                title: "Training preferences",
                subtitle: "These shape how your weekly schedule and sessions are structured."
            )

            // Focus area
            VStack(alignment: .leading, spacing: 10) {
                Text("Where do you want to focus?")
                    .font(.system(size: 15, weight: .medium))
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 8
                ) {
                    ForEach(FocusArea.allCases, id: \.self) { area in
                        Button {
                            viewModel.response.focusArea = area
                        } label: {
                            VStack(spacing: 6) {
                                Text(area.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                                Text(area.muscles)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.appT3)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .background(viewModel.response.focusArea == area
                                        ? Color.appLime.opacity(0.12)
                                        : Color.appBG2)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(viewModel.response.focusArea == area
                                        ? Color.appLime : Color.clear,
                                        lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Session length
            VStack(alignment: .leading, spacing: 10) {
                Text("How long per session?")
                    .font(.system(size: 15, weight: .medium))
                HStack(spacing: 8) {
                    ForEach(SessionLength.allCases, id: \.self) { length in
                        Button {
                            viewModel.response.sessionLength = length
                        } label: {
                            Text(length.rawValue)
                                .font(.system(
                                    size: 12,
                                    weight: viewModel.response.sessionLength == length
                                        ? .medium : .regular
                                ))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(viewModel.response.sessionLength == length
                                            ? Color.appLime
                                            : Color.appBG2)
                                .foregroundStyle(viewModel.response.sessionLength == length
                                                 ? .white : Color.primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Training days
            VStack(alignment: .leading, spacing: 10) {
                Text("How many days per week can you train?")
                    .font(.system(size: 15, weight: .medium))
                HStack(spacing: 10) {
                    ForEach(TrainingDays.allCases, id: \.self) { option in
                        Button {
                            viewModel.response.trainingDays = option
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(option.rawValue)")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(viewModel.response.trainingDays == option
                                                     ? .white : Color.primary)
                                Text("days")
                                    .font(.system(size: 11))
                                    .foregroundStyle(viewModel.response.trainingDays == option
                                                     ? .white.opacity(0.8) : Color.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(viewModel.response.trainingDays == option
                                        ? Color.appLime
                                        : Color.appBG2)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Equipment

    private var equipmentStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "What equipment do you have?",
                subtitle: "Select everything available at home. Your exercises will use exactly what you own — nothing else."
            )

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                ForEach(HomeEquipment.allCases, id: \.self) { item in
                    EquipmentCard(
                        equipment: item,
                        isSelected: viewModel.response.equipment.contains(item)
                    ) {
                        viewModel.toggleEquipment(item)
                    }
                }
            }

            // Space available
            VStack(alignment: .leading, spacing: 10) {
                Text("Available floor space")
                    .font(.system(size: 15, weight: .medium))
                HStack(spacing: 8) {
                    ForEach(
                        [("Tiny", 20), ("Small", 50), ("Medium", 100), ("Large", 200)],
                        id: \.0
                    ) { label, sqft in
                        Button {
                            viewModel.response.spaceAvailableSqFt = sqft
                        } label: {
                            VStack(spacing: 3) {
                                Text(label)
                                    .font(.system(size: 12, weight: .medium))
                                Text("\(sqft) sq ft")
                                    .font(.system(size: 10))
                                    .foregroundStyle(
                                        viewModel.response.spaceAvailableSqFt == sqft
                                        ? .white.opacity(0.8) : Color.secondary
                                    )
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                viewModel.response.spaceAvailableSqFt == sqft
                                ? Color.appLime
                                : Color.appBG2
                            )
                            .foregroundStyle(
                                viewModel.response.spaceAvailableSqFt == sqft
                                ? .white : Color.primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if viewModel.response.spaceAvailableSqFt < 50 {
                infoBox("Tight spaces work fine — we will stick to standing and small-footprint exercises.")
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Summary

    private var summaryStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Your profile summary",
                subtitle: "Review your details before we generate your personalised programme."
            )

            let r = viewModel.response

            VStack(spacing: 0) {
                SummaryRow(label: "Name",         value: r.name)
                SummaryRow(label: "Age",          value: "\(r.age) years")
                SummaryRow(label: "Height",       value: "\(Int(r.heightCM)) cm")
                SummaryRow(label: "Weight",       value: "\(Int(r.weightKG)) kg")
                SummaryRow(label: "Experience",   value: r.experience.rawValue)
                SummaryRow(label: "Goal",         value: r.primaryGoal.rawValue)
                SummaryRow(label: "Focus",        value: r.focusArea.rawValue)
                SummaryRow(label: "Session",      value: r.sessionLength.rawValue)
                SummaryRow(label: "Days/week",    value: "\(r.trainingDays.rawValue) days")
                SummaryRow(
                    label: "Equipment",
                    value: r.equipment.map { $0.rawValue }.joined(separator: ", "),
                    isLast: true
                )
            }
            .background(Color.appBG)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5))

            if r.parqResult.requiresMedicalClearance {
                warningBox("Medical clearance recommended based on your PAR-Q responses. Your plan will be gentle and safe.")
            }

            if !r.conditions.contains(.none) {
                infoBox("Exercises adjusted for: \(r.conditions.filter { $0 != .none }.map { $0.rawValue }.joined(separator: ", "))")
            }

            infoBox("Tap 'Generate my plan' to create your personalised programme using all of the above.")
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Generating view

    private var generatingView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.appLime.opacity(0.12))
                    .frame(width: 100, height: 100)
                ProgressView()
                    .tint(Color.appLime)
                    .scaleEffect(1.5)
            }
            VStack(spacing: 8) {
                Text("Building your plan...")
                    .font(.system(size: 20, weight: .medium))
                Text("Analysing your responses and creating\na personalised home workout programme")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appT3)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            Spacer()
        }
    }

    // MARK: - Navigation buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if viewModel.currentStep.rawValue > 0 {
                Button {
                    viewModel.previousStep()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 52, height: 52)
                        .background(Color.appBG2)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            Button {
                viewModel.nextStep()
            } label: {
                Text(
                    viewModel.currentStep == .summary
                    ? "Generate my plan"
                    : viewModel.currentStep == .welcome
                    ? "Let's start"
                    : "Continue"
                )
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(viewModel.canProceed
                             ? Color.appLime
                             : Color.secondary.opacity(0.2))
                .foregroundStyle(viewModel.canProceed ? .white : Color.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!viewModel.canProceed)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .padding(.top, 8)
        .background(.ultraThinMaterial)
    }

    // MARK: - Helpers

    private func saveAndContinue() {
        appState.markGoalComplete(goal: viewModel.generatedPlan?.goal ?? .stayingActive)
        appState.markProfileComplete()
    }

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 22, weight: .medium))
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appT3)
                    .lineSpacing(3)
            }
        }
    }

    private func levelIcon(_ level: ExperienceLevel) -> String {
        switch level {
        case .beginner:     return "figure.walk"
        case .intermediate: return "figure.run"
        case .advanced:     return "figure.strengthtraining.traditional"
        }
    }

    private func levelDescription(_ level: ExperienceLevel) -> String {
        switch level {
        case .beginner:     return "Less than 3 months consistent training"
        case .intermediate: return "3–12 months, comfortable with basics"
        case .advanced:     return "Over 1 year, training regularly"
        }
    }

    private func infoBox(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "378ADD"))
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Color.appT3)
                .lineSpacing(3)
        }
        .padding(12)
        .background(Color(hex: "E6F1FB").opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func warningBox(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.appWarn)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Color.appT3)
                .lineSpacing(3)
        }
        .padding(12)
        .background(Color(hex: "FAEEDA").opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Reusable components

struct FeatureRow: View {
    let icon: String
    let color: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: color))
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Color.primary)
        }
    }
}

struct QTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.appT3)
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.appBG2)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct QNumberField: View {
    let label: String
    let placeholder: String
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.appT3)
            TextField(placeholder, text: $value)
                .keyboardType(.numberPad)
                .font(.system(size: 15))
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.appBG2)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct PARQRow: View {
    let question: String
    @Binding var value: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(question)
                .font(.system(size: 13))
                .foregroundStyle(Color.primary)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Button("Yes") { value = true }
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(value ? Color(hex: "FAECE7") : Color.appBG2)
                    .foregroundStyle(value ? Color.appMove : Color.secondary)
                    .clipShape(Capsule())

                Button("No") { value = false }
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(!value ? Color(hex: "E1F5EE") : Color.appBG2)
                    .foregroundStyle(!value ? Color.appGood : Color.secondary)
                    .clipShape(Capsule())
            }
            .fixedSize()
        }
        .padding(12)
        .background(Color.appBG2)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct SelfTestInput: View {
    let title: String
    let subtitle: String
    let icon: String
    let unit: String
    @Binding var value: Int
    @State private var text: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.appLime)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appT3)
                }
            }
            HStack(spacing: 10) {
                TextField("0", text: $text)
                    .keyboardType(.numberPad)
                    .font(.system(size: 18, weight: .medium))
                    .multilineTextAlignment(.center)
                    .frame(width: 80, height: 44)
                    .background(Color.appBG2)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onChange(of: text) { _, val in
                        value = Int(val) ?? 0
                    }
                Text(unit)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appT3)
            }
        }
        .padding(14)
        .background(Color.appBG2.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appT3)
                Spacer()
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            if !isLast {
                Divider().padding(.leading, 16)
            }
        }
    }
}
