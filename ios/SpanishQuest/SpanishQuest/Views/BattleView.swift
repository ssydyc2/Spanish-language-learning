import Combine
import SpriteKit
import SwiftUI
import UIKit

struct BattleView: View {
    @StateObject private var viewModel = BattleViewModel()
    @StateObject private var keyboard = KeyboardObserver()
    @State private var scene = BattleScene(size: CGSize(width: 390, height: 520))

    var body: some View {
        GeometryReader { proxy in
            let arenaHeight = keyboard.isVisible
                ? max(220, min(300, proxy.size.height * 0.35))
                : max(360, proxy.size.height * 0.58)

            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    SpriteView(scene: scene, options: [.allowsTransparency])
                        .ignoresSafeArea(edges: .top)
                        .onAppear {
                            scene.size = CGSize(width: proxy.size.width, height: arenaHeight)
                            if viewModel.prompt.audioPath != nil {
                                viewModel.playPromptAudio()
                            }
                        }
                        .onChange(of: proxy.size) { _, newSize in
                            scene.size = CGSize(width: newSize.width, height: arenaHeight)
                        }
                        .onChange(of: arenaHeight) { _, newHeight in
                            scene.size = CGSize(width: proxy.size.width, height: newHeight)
                        }
                        .onChange(of: viewModel.animationEvent?.id) { _, _ in
                            if let event = viewModel.animationEvent {
                                scene.apply(event: event)
                            }
                        }

                    HStack(alignment: .top, spacing: 14) {
                        HPBarView(title: "Hero", hp: viewModel.playerHP, maxHP: 100, alignment: .leading)
                        Spacer(minLength: 8)
                        HPBarView(title: "Imp", hp: viewModel.monsterHP, maxHP: 100, alignment: .trailing)
                    }
                    .padding(.top, 14)
                    .padding(.horizontal, 14)
                }
                .frame(height: arenaHeight)
                .animation(.spring(response: 0.36, dampingFraction: 0.9), value: arenaHeight)

                ScrollView {
                    QuizPanelView(viewModel: viewModel)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .scrollDismissesKeyboard(.interactively)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.10, green: 0.08, blue: 0.07))
            }
            .background(Color(red: 0.10, green: 0.08, blue: 0.07))
        }
    }
}

private final class KeyboardObserver: ObservableObject {
    @Published var height: CGFloat = 0

    var isVisible: Bool {
        height > 0
    }

    private var cancellables: Set<AnyCancellable> = []

    init() {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .compactMap(Self.keyboardHeight)
            .receive(on: RunLoop.main)
            .assign(to: \.height, on: self)
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat.zero }
            .receive(on: RunLoop.main)
            .assign(to: \.height, on: self)
            .store(in: &cancellables)
    }

    private static func keyboardHeight(from notification: Notification) -> CGFloat? {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return nil
        }

        return max(0, UIScreen.main.bounds.maxY - frame.minY)
    }
}
