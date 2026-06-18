import SwiftUI

struct HPBarView: View {
    let title: String
    let hp: Int
    let maxHP: Int
    let alignment: HorizontalAlignment

    private var fraction: CGFloat {
        CGFloat(max(0, min(hp, maxHP))) / CGFloat(maxHP)
    }

    var body: some View {
        VStack(alignment: alignment, spacing: 5) {
            HStack(spacing: 6) {
                if alignment == .trailing {
                    Spacer(minLength: 0)
                }
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(hp)/\(maxHP)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
                if alignment == .leading {
                    Spacer(minLength: 0)
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: alignment == .leading ? .leading : .trailing) {
                    Capsule()
                        .fill(Color(red: 0.20, green: 0.06, blue: 0.04))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.18, blue: 0.16),
                                    Color(red: 0.75, green: 0.02, blue: 0.04)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: max(8, proxy.size.width * fraction))
                }
                .overlay {
                    Capsule()
                        .stroke(Color(red: 0.93, green: 0.67, blue: 0.28), lineWidth: 2)
                }
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: hp)
            }
            .frame(height: 14)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.16, green: 0.11, blue: 0.07).opacity(0.86))
                .stroke(Color(red: 0.87, green: 0.62, blue: 0.26).opacity(0.78), lineWidth: 1)
        )
    }
}
