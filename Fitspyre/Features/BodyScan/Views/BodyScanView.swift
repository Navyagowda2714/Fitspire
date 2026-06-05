//
//  BodyScanView.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 01/05/2026.
//

import SwiftUI
import SwiftData

struct BodyScanView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = BodyScanViewModel()
    @State private var showResult = false

    var body: some View {
        ZStack {
            // Camera feed
            CameraPreview(session: viewModel.cameraManager.session)
                .ignoresSafeArea()

            // Skeleton overlay
            if let body = viewModel.detectedBody {
                GeometryReader { geo in
                    SkeletonOverlayView(
                        detectedBody: body,
                        size: geo.size
                    )
                }
                .ignoresSafeArea()
            }

            // UI overlay
            VStack {
                // Top bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Body scan")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                        Text("Stand 2m away · full body visible")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    // Tracking indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(viewModel.detectedBody != nil
                                  ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(viewModel.detectedBody != nil
                             ? "Tracking" : "Searching...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                // Bottom panel
                VStack(spacing: 16) {
                    if viewModel.detectedBody != nil {
                        Text("Body detected — tap scan to analyse your posture")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Make sure your full body is visible in frame")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        viewModel.performScan()
                    } label: {
                        HStack(spacing: 10) {
                            if viewModel.isScanning {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.9)
                                Text("Scanning...")
                            } else {
                                Image(systemName: "camera.viewfinder")
                                Text("Scan my posture")
                            }
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            viewModel.detectedBody != nil
                            ? Color(hex: "7F77DD")
                            : Color.white.opacity(0.2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(viewModel.detectedBody == nil || viewModel.isScanning)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear { viewModel.startCamera() }
        .onDisappear { viewModel.stopCamera() }
        .sheet(isPresented: $viewModel.scanComplete) {
            ScanResultView(viewModel: viewModel) {
                viewModel.saveResult(context: context)
                appState.markOnboardingComplete()
            }
        }
    }
}
