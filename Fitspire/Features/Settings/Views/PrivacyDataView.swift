//
//  PrivacyDataView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 06/05/2026.
//

//
//  PrivacyDataView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 06/05/2026.
//


import SwiftUI
import SwiftData

struct PrivacyDataView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @Query private var scanResults: [BodyScanResult]
    @Query private var mealPlans: [MealPlan]
    @Query private var workoutPlans: [WorkoutPlan]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("FitnessAI stores all your data on this device only. Nothing is sent to any server unless you enable iCloud sync, which stores data only in your personal Apple iCloud account.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appT3)
                        .listRowBackground(Color.clear)
                }

                Section {
                    DataRow(
                        icon: "person.fill",
                        label: "Profile",
                        detail: profiles.isEmpty
                            ? "No data"
                            : "1 profile stored"
                    )
                    DataRow(
                        icon: "camera.viewfinder",
                        label: "Body scans",
                        detail: "\(scanResults.count) scans stored"
                    )
                    DataRow(
                        icon: "list.bullet.clipboard",
                        label: "Workout plans",
                        detail: "\(workoutPlans.count) plans stored"
                    )
                    DataRow(
                        icon: "fork.knife",
                        label: "Meal plans",
                        detail: "\(mealPlans.count) plans stored"
                    )
                } header: {
                    Text("Data stored on this device")
                }

                Section {
                    DataRow(
                        icon: "camera.fill",
                        label: "Camera",
                        detail: "Video never stored or uploaded"
                    )
                    DataRow(
                        icon: "heart.fill",
                        label: "Apple Health",
                        detail: "Read and write with your permission"
                    )
                    DataRow(
                        icon: "applewatch",
                        label: "Apple Watch",
                        detail: "Alert messages only, not stored"
                    )
                } header: {
                    Text("Permissions used")
                }

                Section {
                    DataRow(
                        icon: "xmark.shield.fill",
                        label: "No ads",
                        detail: "Fitspire never shows advertisements"
                    )
                    DataRow(
                        icon: "hand.raised.fill",
                        label: "No tracking",
                        detail: "We do not track you across apps"
                    )
                    DataRow(
                        icon: "dollarsign.circle.fill",
                        label: "No data sales",
                        detail: "Your data is never sold"
                    )
                } header: {
                    Text("Our promises")
                }
            }
            .navigationTitle("Privacy and data")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct DataRow: View {
    let icon: String
    let label: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.appLime)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appT3)
            }
        }
        .padding(.vertical, 3)
    }
}
