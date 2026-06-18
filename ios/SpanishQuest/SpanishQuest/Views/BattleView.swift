import SpriteKit
import SwiftUI

struct BattleView: View {
    @StateObject private var viewModel = BattleViewModel()
    @State private var scene = BattleScene(size: CGSize(width: 390, height: 520))

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    SpriteView(scene: scene, options: [.allowsTransparency])
                        .ignoresSafeArea(edges: .top)
                        .onAppear {
                            scene.size = CGSize(width: proxy.size.width, height: max(360, proxy.size.height * 0.58))
                            if viewModel.prompt.audioPath != nil {
                                viewModel.playPromptAudio()
                            }
                        }
                        .onChange(of: proxy.size) { _, newSize in
                            scene.size = CGSize(width: newSize.width, height: max(360, newSize.height * 0.58))
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
                .frame(height: max(360, proxy.size.height * 0.58))

                QuizPanelView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(red: 0.10, green: 0.08, blue: 0.07))
            }
            .background(Color(red: 0.10, green: 0.08, blue: 0.07))
        }
    }
}
