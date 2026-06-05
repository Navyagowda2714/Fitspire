

import SwiftUI

struct WorkoutDashboardView: View {
    @EnvironmentObject var appState: AppState

    // Using item-based fullScreenCover to avoid the race condition where
    // isPresented fires before the exercise is set → blank black screen.
    @State private var demoExercise:    HomeExercise? = nil   // drives demo sheet
    @State private var cameraExercise:  ExerciseType? = nil   // drives camera sheet
    @State private var selectedCategory: HomeExercise.Category? = nil  // category filter
    // Stores the HomeExercise for the camera session — persists after demoExercise = nil
    @State private var cameraHomeExercise: HomeExercise? = nil
    // Drives the AIFormCheckIntroView (shown between demo and camera)
    @State private var introExercise: HomeExercise? = nil

    private var exercises: [HomeExercise] {
        guard let cat = selectedCategory else {
            return HomeExerciseLibrary.bodyweight
        }
        return HomeExerciseLibrary.bodyweight.filter { $0.category == cat }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBG.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // ── Header ───────────────────────────────────────────────
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formattedDate())
                                    .font(.system(size: 11, weight: .bold)).kerning(0.6)
                                    .foregroundStyle(Color.appT3)
                                Text("Hey, \(appState.userProfile?.name ?? "Athlete") 👋")
                                    .font(.system(size: 28, weight: .heavy)).foregroundStyle(.white)
                            }
                            Spacer()
                            ZStack {
                                Circle().fill(Color.appBG2).frame(width: 42, height: 42)
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 16)).foregroundStyle(Color.appLime)
                            }
                        }
                        .padding(.horizontal, 24).padding(.top, 16)

                        // ── Today's goal card ────────────────────────────────────
                        HStack(spacing: 12) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 20)).foregroundStyle(Color.appLime)
                                .frame(width: 44, height: 44)
                                .background(Color.appLime.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Today's goal").font(.system(size: 12)).foregroundStyle(Color.appT3)
                                Text(appState.selectedGoal?.rawValue ?? "Home Workout")
                                    .font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                            }
                            Spacer()
                            Text("Bodyweight")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.appGood)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Color.appGood.opacity(0.12)).clipShape(Capsule())
                        }
                        .padding(16)
                        .background(Color.appBG2)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appHair, lineWidth: 0.5))
                        .padding(.horizontal, 24)

                        // ── Exercise library ─────────────────────────────────────
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("EXERCISES").font(.system(size: 11, weight: .bold)).kerning(1.4)
                                    .foregroundStyle(Color.appT3)
                                Spacer()
                                Text("\(exercises.count) available")
                                    .font(.system(size: 12)).foregroundStyle(Color.appT3)
                            }
                            .padding(.horizontal, 24)

                            // Category filter pills
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    // "All" pill
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedCategory = nil
                                        }
                                    } label: {
                                        Text("All (\(HomeExerciseLibrary.bodyweight.count))")
                                            .font(.system(size: 12, weight: selectedCategory == nil ? .bold : .medium))
                                            .foregroundStyle(selectedCategory == nil ? .black : Color.appT2)
                                            .padding(.horizontal, 14).padding(.vertical, 7)
                                            .background(selectedCategory == nil ? Color.appLime : Color.appBG2)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(selectedCategory == nil ? Color.appLime : Color.appHair2, lineWidth: 1))
                                    }.buttonStyle(.plain)

                                    ForEach(HomeExercise.Category.allCases, id: \.rawValue) { cat in
                                        let count = HomeExerciseLibrary.bodyweight.filter { $0.category == cat }.count
                                        if count > 0 {
                                            let isSelected = selectedCategory == cat
                                            Button {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    selectedCategory = isSelected ? nil : cat
                                                }
                                            } label: {
                                                Text("\(cat.rawValue) (\(count))")
                                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                                    .foregroundStyle(isSelected ? .black : Color.appT2)
                                                    .padding(.horizontal, 14).padding(.vertical, 7)
                                                    .background(isSelected ? Color.appLime : Color.appBG2)
                                                    .clipShape(Capsule())
                                                    .overlay(Capsule().stroke(isSelected ? Color.appLime : Color.appHair2, lineWidth: 1))
                                            }.buttonStyle(.plain)
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }

                            // Exercise cards
                            VStack(spacing: 10) {
                                ForEach(exercises) { exercise in
                                    ExerciseCard(exercise: exercise) {
                                        demoExercise = exercise   // item-based cover — no race condition
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("").navigationBarHidden(true)

            // ── Demo sheet: item-based — exercise is GUARANTEED non-nil ────────
            // (isPresented: caused a race condition → exercise set AFTER cover opened → black screen)
            .fullScreenCover(item: $demoExercise) { ex in
                HomeExerciseDemoView(
                    exercise: ex,
                    onStartCamera: ex.poseType != nil ? {
                        cameraHomeExercise = ex     // save before clearing
                        demoExercise = nil           // dismiss demo
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            introExercise = ex       // open intro screen first
                        }
                    } : {}

                )
            }

            // ── Intro screen (between demo and camera) ──────────────────────
            .fullScreenCover(item: $introExercise) { ex in
                AIFormCheckIntroView(exercise: ex) {
                    // User tapped "Open Camera" — dismiss intro then open camera
                    let poseType = ex.poseType!
                    introExercise = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        cameraExercise = poseType
                    }
                }
            }

            // ── Camera live workout: always uses ExerciseLiveView ─────────────
            .fullScreenCover(item: $cameraExercise) { poseType in
                if let homeEx = cameraHomeExercise {
                    ExerciseLiveView(exercise: homeEx)
                } else {
                    ExerciseLiveView(
                        exercise: HomeExerciseLibrary.bodyweight.first(where: { $0.poseType == poseType })
                            ?? HomeExerciseLibrary.bodyweight[0]
                    )
                }
            }

        }
    }

    private func formattedDate() -> String {
        let f = DateFormatter(); f.dateFormat = "EEEE · MMM d"
        return f.string(from: Date()).uppercased()
    }
}

// MARK: - Exercise Card

struct ExerciseCard: View {
    let exercise: HomeExercise
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: exercise.difficulty.color).opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: exercise.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(Color(hex: exercise.difficulty.color))
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(exercise.name)
                            .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                        if exercise.poseType != nil {
                            // AI badge
                            HStack(spacing: 3) {
                                Image(systemName: "brain.head.profile").font(.system(size: 9))
                                Text("AI").font(.system(size: 9, weight: .bold))
                            }
                            .foregroundStyle(Color.appCyan)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.appCyan.opacity(0.12)).clipShape(Capsule())
                        }
                    }

                    Text(exercise.targetMuscles)
                        .font(.system(size: 12)).foregroundStyle(Color.appT3)
                        .lineLimit(1)

                    HStack(spacing: 10) {
                        Text(exercise.repsOrTime)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.appLime)
                        Text("·").foregroundStyle(Color.appT4)
                        Text("\(exercise.sets) sets")
                            .font(.system(size: 11)).foregroundStyle(Color.appT3)
                        Text("·").foregroundStyle(Color.appT4)
                        Text(exercise.difficulty.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: exercise.difficulty.color))
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.appT4)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(Color.appBG2)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appHair, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

// Make Category CaseIterable for filter pills
extension HomeExercise.Category: CaseIterable {
    public static var allCases: [HomeExercise.Category] {
        [.core, .upperBody, .lowerBody, .fullBody, .cardio]
    }
}


// MARK: - ExerciseType Identifiable (needed for fullScreenCover(item:))
extension ExerciseType: Identifiable {
    public var id: String { rawValue }
}
