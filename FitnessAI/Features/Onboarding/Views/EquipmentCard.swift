//
//  EquipmentCard.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 08/05/2026.
//

//  EquipmentCard.swift — FitnessAI
import SwiftUI

struct EquipmentCard: View {
    let equipment: HomeEquipment
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Text(equipment.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? .black : .white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.black).font(.system(size: 18))
                }
            }
            .padding(16)
            .background(isSelected ? Color.appLime : Color.appBG2)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Color.appLime : Color.appHair, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSelected)
    }
}
