import SwiftUI
import SpriteKit
import UIKit

enum VillageSceneID: String {
    case village
    case school
    case cafe
    case library
}

struct VillageScene {
    let id: VillageSceneID
    let title: String
    let subtitle: String
    let backgroundImageName: String
    let size: CGSize
    let spawnPoint: CGPoint
    let walkableAreas: [WalkableArea]
    let portals: [VillagePortal]
    let characters: [VillageCharacter]

    static func scene(for id: VillageSceneID) -> VillageScene {
        switch id {
        case .village:
            village
        case .school:
            school
        case .cafe:
            cafe
        case .library:
            library
        }
    }

    static let village = VillageScene(
        id: .village,
        title: "Pueblo Espanol",
        subtitle: "Move freely around the village. Enter buildings to find new scenes.",
        backgroundImageName: "village_map_sim",
        size: CGSize(width: 1254, height: 1254),
        spawnPoint: CGPoint(x: 625, y: 700),
        walkableAreas: [
            .ellipse(CGRect(x: 390, y: 430, width: 480, height: 360)),
            .rect(CGRect(x: 485, y: 250, width: 280, height: 520)),
            .rect(CGRect(x: 430, y: 720, width: 250, height: 540)),
            .rect(CGRect(x: 210, y: 560, width: 370, height: 160)),
            .rect(CGRect(x: 675, y: 575, width: 360, height: 155)),
            .rect(CGRect(x: 775, y: 815, width: 260, height: 250)),
            .rect(CGRect(x: 500, y: 360, width: 230, height: 80)),
            .rect(CGRect(x: 915, y: 620, width: 120, height: 120)),
            .rect(CGRect(x: 840, y: 980, width: 120, height: 95))
        ],
        portals: [
            VillagePortal(
                id: "school-door",
                title: "School",
                actionTitle: "Enter School",
                icon: "graduationcap.fill",
                frame: CGRect(x: 535, y: 250, width: 180, height: 155),
                destination: .school,
                destinationSpawn: CGPoint(x: 625, y: 980)
            ),
            VillagePortal(
                id: "cafe-door",
                title: "Cafe",
                actionTitle: "Enter Cafe",
                icon: "cup.and.saucer.fill",
                frame: CGRect(x: 920, y: 490, width: 180, height: 155),
                destination: .cafe,
                destinationSpawn: CGPoint(x: 625, y: 880)
            ),
            VillagePortal(
                id: "library-door",
                title: "Library",
                actionTitle: "Enter Library",
                icon: "books.vertical.fill",
                frame: CGRect(x: 820, y: 860, width: 210, height: 170),
                destination: .library,
                destinationSpawn: CGPoint(x: 625, y: 930)
            )
        ],
        characters: []
    )

    static let school = VillageScene(
        id: .school,
        title: "Village School",
        subtitle: "A future classroom scene for lessons and mini games.",
        backgroundImageName: "school_interior_sim",
        size: CGSize(width: 1254, height: 1254),
        spawnPoint: CGPoint(x: 625, y: 980),
        walkableAreas: [
            .rect(CGRect(x: 350, y: 520, width: 560, height: 600)),
            .rect(CGRect(x: 455, y: 1025, width: 345, height: 180))
        ],
        portals: [
            VillagePortal(
                id: "school-exit",
                title: "Village Plaza",
                actionTitle: "Exit School",
                icon: "door.left.hand.open",
                frame: CGRect(x: 455, y: 1025, width: 345, height: 180),
                destination: .village,
                destinationSpawn: CGPoint(x: 625, y: 410)
            )
        ],
        characters: []
    )

    static let cafe = VillageScene(
        id: .cafe,
        title: "Village Cafe",
        subtitle: "A future conversation scene for ordering food in Spanish.",
        backgroundImageName: "cafe_interior_sim",
        size: CGSize(width: 1254, height: 1254),
        spawnPoint: CGPoint(x: 625, y: 880),
        walkableAreas: [
            .rect(CGRect(x: 290, y: 470, width: 560, height: 550)),
            .rect(CGRect(x: 555, y: 235, width: 190, height: 280))
        ],
        portals: [
            VillagePortal(
                id: "cafe-exit",
                title: "Village Plaza",
                actionTitle: "Exit Cafe",
                icon: "door.left.hand.open",
                frame: CGRect(x: 555, y: 235, width: 190, height: 210),
                destination: .village,
                destinationSpawn: CGPoint(x: 990, y: 650)
            )
        ],
        characters: []
    )

    static let library = VillageScene(
        id: .library,
        title: "Village Library",
        subtitle: "Walk close to the scholar to practice Spanish.",
        backgroundImageName: "library_interior_sim",
        size: CGSize(width: 1254, height: 1254),
        spawnPoint: CGPoint(x: 625, y: 930),
        walkableAreas: [
            .rect(CGRect(x: 350, y: 520, width: 590, height: 555)),
            .rect(CGRect(x: 450, y: 1050, width: 360, height: 165))
        ],
        portals: [
            VillagePortal(
                id: "library-exit",
                title: "Village Plaza",
                actionTitle: "Exit Library",
                icon: "door.left.hand.open",
                frame: CGRect(x: 450, y: 1050, width: 360, height: 165),
                destination: .village,
                destinationSpawn: CGPoint(x: 900, y: 1000)
            )
        ],
        characters: [
            VillageCharacter(
                id: "scholar",
                name: "Scholar",
                role: "Spanish Tutor",
                greeting: "Bienvenido. Let's practice Spanish in the library.",
                position: CGPoint(x: 650, y: 610),
                imageName: "scholar_npc",
                accent: Color(red: 0.15, green: 0.45, blue: 0.62),
                symbol: "person.crop.circle.badge.questionmark"
            )
        ]
    )
}

enum WalkableArea {
    case rect(CGRect)
    case ellipse(CGRect)

    func contains(_ point: CGPoint) -> Bool {
        switch self {
        case .rect(let rect):
            return rect.contains(point)
        case .ellipse(let rect):
            guard rect.width > 0, rect.height > 0 else {
                return false
            }

            let normalizedX = (point.x - rect.midX) / (rect.width / 2)
            let normalizedY = (point.y - rect.midY) / (rect.height / 2)
            return normalizedX * normalizedX + normalizedY * normalizedY <= 1
        }
    }
}

struct VillagePortal: Identifiable {
    let id: String
    let title: String
    let actionTitle: String
    let icon: String
    let frame: CGRect
    let destination: VillageSceneID
    let destinationSpawn: CGPoint
}

struct VillageCharacter: Identifiable, Equatable {
    let id: String
    let name: String
    let role: String
    let greeting: String
    let position: CGPoint
    let imageName: String
    let accent: Color
    let symbol: String

    static func == (lhs: VillageCharacter, rhs: VillageCharacter) -> Bool {
        lhs.id == rhs.id
    }
}

struct WorldMapView: View {
    @State private var gameScene = VillageExploreScene(size: UIScreen.main.bounds.size)
    @State private var activeScene = VillageScene.village
    @State private var statusText = "Explore the village. School, cafe, and library are enterable."
    @State private var primaryActionTitle = "Explore"
    @State private var canUsePrimaryAction = false
    @State private var activeConversation: VillageCharacter?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(red: 0.08, green: 0.13, blue: 0.11)
                    .ignoresSafeArea()

                SpriteView(scene: gameScene)
                    .ignoresSafeArea()
                    .accessibilityLabel(activeScene.title)

                VStack(spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        VillageHeader(scene: activeScene, statusText: statusText)

                        ZoomControls(
                            canZoomIn: true,
                            canZoomOut: true,
                            zoomIn: gameScene.zoomIn,
                            zoomOut: gameScene.zoomOut
                        )
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)

                    Spacer()

                    VillageControls(
                        primaryTitle: primaryActionTitle,
                        canUsePrimary: canUsePrimaryAction,
                        moveVector: gameScene.setInputVector,
                        usePrimary: gameScene.performPrimaryAction
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Spanish Village")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: configureSceneCallbacks)
            .sheet(item: $activeConversation) { character in
                ScholarPracticeView(character: character)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func configureSceneCallbacks() {
        gameScene.onSceneChange = { scene in
            activeScene = scene
        }

        gameScene.onStatusChange = { text in
            statusText = text
        }

        gameScene.onActionChange = { title, enabled in
            primaryActionTitle = title
            canUsePrimaryAction = enabled
        }

        gameScene.onPracticeRequested = { character in
            activeConversation = character
        }
    }
}

private struct VillageHeader: View {
    let scene: VillageScene
    let statusText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: scene.id == .village ? "map.fill" : "house.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.36))

                VStack(alignment: .leading, spacing: 1) {
                    Text(scene.title)
                        .font(.system(size: 23, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(scene.subtitle)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.84))
                }

                Spacer()
            }

            Text(statusText)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.90))
                .lineLimit(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.44))
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct ZoomControls: View {
    let canZoomIn: Bool
    let canZoomOut: Bool
    let zoomIn: () -> Void
    let zoomOut: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: zoomIn) {
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 17, weight: .black))
                    .frame(width: 44, height: 40)
            }
            .disabled(!canZoomIn)

            Button(action: zoomOut) {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 17, weight: .black))
                    .frame(width: 44, height: 40)
            }
            .disabled(!canZoomOut)
        }
        .foregroundStyle(.white)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.44))
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .buttonStyle(.plain)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Zoom controls")
    }
}

private struct VillageControls: View {
    let primaryTitle: String
    let canUsePrimary: Bool
    let moveVector: (CGSize) -> Void
    let usePrimary: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 14) {
            CircularMovePad(moveVector: moveVector)

            Spacer()

            Button(action: usePrimary) {
                HStack(spacing: 8) {
                    Image(systemName: canUsePrimary ? "hand.tap.fill" : "sparkles")
                    Text(primaryTitle)
                }
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(canUsePrimary ? Color(red: 0.13, green: 0.16, blue: 0.13) : .white.opacity(0.70))
                .frame(width: 160, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(canUsePrimary ? Color(red: 1.0, green: 0.84, blue: 0.36) : Color.black.opacity(0.38))
                        .stroke(Color.white.opacity(canUsePrimary ? 0.72 : 0.18), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canUsePrimary)
            .accessibilityLabel(primaryTitle)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.38))
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
    }
}

private struct CircularMovePad: View {
    let moveVector: (CGSize) -> Void
    @State private var knobOffset = CGSize.zero
    @State private var activeVector = CGSize.zero

    private let padSize: CGFloat = 118
    private let knobSize: CGFloat = 46
    private let maxOffset: CGFloat = 38

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.38))
                .stroke(Color.white.opacity(0.22), lineWidth: 2)

            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 82, height: 82)

            Circle()
                .fill(Color(red: 0.17, green: 0.56, blue: 0.48))
                .stroke(Color.white.opacity(0.70), lineWidth: 2)
                .frame(width: knobSize, height: knobSize)
                .shadow(color: Color.black.opacity(0.25), radius: 5, y: 3)
                .offset(knobOffset)
        }
        .frame(width: padSize, height: padSize)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let center = CGPoint(x: padSize / 2, y: padSize / 2)
                    let raw = CGSize(
                        width: value.location.x - center.x,
                        height: value.location.y - center.y
                    )
                    let clamped = clamp(raw)
                    knobOffset = clamped
                    activeVector = CGSize(width: clamped.width / maxOffset, height: clamped.height / maxOffset)
                    moveVector(activeVector)
                }
                .onEnded { _ in
                    knobOffset = .zero
                    activeVector = .zero
                    moveVector(.zero)
                }
        )
        .onDisappear {
            moveVector(.zero)
        }
        .accessibilityLabel("Movement control")
    }

    private func clamp(_ value: CGSize) -> CGSize {
        let length = hypot(value.width, value.height)
        guard length > maxOffset else {
            return value
        }

        let scale = maxOffset / length
        return CGSize(width: value.width * scale, height: value.height * scale)
    }
}

private struct ScholarPracticeView: View {
    let character: VillageCharacter
    @StateObject private var viewModel = ScholarPracticeViewModel()
    @State private var typedAnswer = ""
    @FocusState private var isAnswerFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                GameArtImage(character.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 58, height: 72)

                VStack(alignment: .leading, spacing: 4) {
                    Text(character.name)
                        .font(.system(size: 25, weight: .black, design: .rounded))
                    Text(character.greeting)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                PracticeStat(title: "Score", value: "\(viewModel.correctCount)")
                PracticeStat(title: "Streak", value: "\(viewModel.streak)")
                PracticeStat(title: "Round", value: "\(viewModel.round)")
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(viewModel.prompt.mode.title)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.16, green: 0.50, blue: 0.66))

                    Spacer()

                    if viewModel.prompt.audioPath != nil {
                        Button {
                            viewModel.playPromptAudio()
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                                .background(Circle().fill(Color(red: 0.16, green: 0.50, blue: 0.66)))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Play audio prompt")
                    }
                }

                Text(viewModel.prompt.question)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.75)
                    .lineLimit(3)

                Text(viewModel.feedback)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(viewModel.lastAnswerWasCorrect ? .green : .secondary)
                    .frame(minHeight: 36, alignment: .topLeading)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )

            if viewModel.prompt.mode == .audioToSpanish {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(viewModel.prompt.choices, id: \.self) { choice in
                        Button {
                            submit(choice)
                        } label: {
                            Text(choice)
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(red: 0.17, green: 0.56, blue: 0.48))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isResolving)
                    }
                }
            } else {
                HStack(spacing: 10) {
                    TextField("Type your answer", text: $typedAnswer)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .focused($isAnswerFocused)
                        .onSubmit {
                            submit(typedAnswer)
                        }
                        .padding(.horizontal, 12)
                        .frame(minHeight: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(uiColor: .secondarySystemBackground))
                                .stroke(Color(red: 0.17, green: 0.56, blue: 0.48).opacity(0.54), lineWidth: 1)
                        )

                    Button {
                        submit(typedAnswer)
                    } label: {
                        Text("Check")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 88)
                            .frame(minHeight: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.36) : Color(red: 0.17, green: 0.56, blue: 0.48))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isResolving)
                }
            }

            Button {
                viewModel.nextPrompt()
            } label: {
                Text("Skip")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.17, green: 0.56, blue: 0.48))
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.17, green: 0.56, blue: 0.48), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isResolving)

            Spacer(minLength: 0)
        }
        .padding(18)
        .onAppear {
            isAnswerFocused = viewModel.prompt.mode != .audioToSpanish
            if viewModel.prompt.audioPath != nil {
                viewModel.playPromptAudio()
            }
        }
        .onChange(of: viewModel.prompt.id) { _, _ in
            typedAnswer = ""
            isAnswerFocused = viewModel.prompt.mode != .audioToSpanish
            if viewModel.prompt.audioPath != nil {
                viewModel.playPromptAudio()
            }
        }
    }

    private func submit(_ answer: String) {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        viewModel.answer(trimmed)
        typedAnswer = ""
    }
}

private struct PracticeStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

@MainActor
private final class ScholarPracticeViewModel: ObservableObject {
    @Published private(set) var prompt: QuizPrompt
    @Published private(set) var correctCount = 0
    @Published private(set) var streak = 0
    @Published private(set) var round = 1
    @Published private(set) var lastAnswerWasCorrect = false
    @Published private(set) var isResolving = false
    @Published var feedback = "Answer the scholar's prompt. No battle, just practice."

    private let quizEngine: QuizEngine
    private let audioPlayer = AudioPlayer()

    init(vocabulary: Vocabulary = VocabularyLoader.load()) {
        quizEngine = QuizEngine(vocabulary: vocabulary)
        prompt = quizEngine.nextPrompt()
    }

    func answer(_ value: String) {
        guard !isResolving else {
            return
        }

        isResolving = true

        if prompt.accepts(value) {
            correctCount += 1
            streak += 1
            lastAnswerWasCorrect = true
            feedback = "Correct. \(prompt.acceptedAnswers.joined(separator: " / "))"
        } else {
            streak = 0
            lastAnswerWasCorrect = false
            feedback = "Not quite. Answer: \(prompt.acceptedAnswers.joined(separator: " / "))"
        }

        Task {
            try? await Task.sleep(for: .milliseconds(700))
            nextPrompt()
        }
    }

    func nextPrompt() {
        round += 1
        prompt = quizEngine.nextPrompt()
        lastAnswerWasCorrect = false
        isResolving = false
        feedback = "Try the next Spanish prompt."
    }

    func playPromptAudio() {
        audioPlayer.play(path: prompt.audioPath)
    }
}

private struct GameArtImage {
    private let image: Image

    init(_ name: String) {
        let bundlePath = Bundle.main.path(forResource: name, ofType: "png")
        let artPath = Bundle.main.path(forResource: name, ofType: "png", inDirectory: "Resources/Art")

        if let uiImage = UIImage(named: name)
            ?? UIImage(contentsOfFile: bundlePath ?? "")
            ?? UIImage(contentsOfFile: artPath ?? "") {
            image = Image(uiImage: uiImage)
        } else {
            image = Image(systemName: "photo")
        }
    }

    func resizable() -> Image {
        image.resizable()
    }
}
