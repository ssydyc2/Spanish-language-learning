import SwiftUI
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

@MainActor
final class VillageGameModel: ObservableObject {
    @Published private(set) var sceneID: VillageSceneID = .village
    @Published var playerPosition = VillageScene.village.spawnPoint
    @Published private(set) var isPlayerMoving = false
    @Published private(set) var playerFacing: CGFloat = 1
    @Published var activeConversation: VillageCharacter?
    @Published var statusText = "Use the circular pad, drag, or tap anywhere to move."

    private let movementStep: CGFloat = 34
    private let portalRange: CGFloat = 105
    private let characterRange: CGFloat = 105
    private var movementTick = 0

    var scene: VillageScene {
        VillageScene.scene(for: sceneID)
    }

    var nearbyPortal: VillagePortal? {
        scene.portals.first { portal in
            portal.frame.insetBy(dx: -portalRange, dy: -portalRange).contains(playerPosition)
        }
    }

    var nearbyCharacter: VillageCharacter? {
        scene.characters.first { character in
            distance(from: playerPosition, to: character.position) <= characterRange
        }
    }

    var primaryActionTitle: String {
        if nearbyCharacter != nil {
            return "Talk"
        }

        return nearbyPortal?.actionTitle ?? "Explore"
    }

    var canUsePrimaryAction: Bool {
        nearbyCharacter != nil || nearbyPortal != nil
    }

    func move(_ direction: VillageDirection) {
        let proposed = CGPoint(
            x: playerPosition.x + direction.delta.width * movementStep,
            y: playerPosition.y + direction.delta.height * movementStep
        )
        movePlayer(to: proposed)
    }

    func move(vector: CGSize) {
        guard vector != .zero else {
            return
        }

        let proposed = CGPoint(
            x: playerPosition.x + vector.width * movementStep,
            y: playerPosition.y + vector.height * movementStep
        )
        movePlayer(to: proposed)
    }

    func movePlayer(to destination: CGPoint) {
        let nextPosition = clamp(destination)
        guard isWalkable(nextPosition, in: scene) else {
            statusText = scene.id == .village
                ? "Stay on the paths to explore the village."
                : "Walk through the open floor area."
            return
        }

        markMoving(from: playerPosition, to: nextPosition)
        playerPosition = nextPosition
        updateStatus()
    }

    func usePrimaryAction() {
        if let nearbyCharacter {
            activeConversation = nearbyCharacter
            return
        }

        guard let nearbyPortal else {
            statusText = "Move near a door or character first."
            return
        }

        enter(nearbyPortal)
    }

    private func enter(_ portal: VillagePortal) {
        sceneID = portal.destination
        playerPosition = clamp(portal.destinationSpawn, in: VillageScene.scene(for: portal.destination))
        isPlayerMoving = false
        statusText = "Entered \(scene.title). Drag or tap to move around this scene."
        updateStatus()
    }

    private func updateStatus() {
        if let nearbyCharacter {
            statusText = "You are near \(nearbyCharacter.name). Tap Talk to practice Spanish."
        } else if let nearbyPortal {
            statusText = "You are near \(nearbyPortal.title). Tap \(nearbyPortal.actionTitle)."
        } else {
            switch sceneID {
            case .village:
                statusText = "Explore the village. School, cafe, and library are enterable."
            case .school:
                statusText = "This classroom can host future lessons. Exit near the bottom door."
            case .cafe:
                statusText = "Cafe conversations can be added here later. Exit through the open door."
            case .library:
                statusText = "Walk close to the scholar to start Spanish practice. Exit near the bottom."
            }
        }
    }

    private func clamp(_ point: CGPoint) -> CGPoint {
        clamp(point, in: scene)
    }

    private func clamp(_ point: CGPoint, in scene: VillageScene) -> CGPoint {
        CGPoint(
            x: min(max(48, point.x), scene.size.width - 48),
            y: min(max(58, point.y), scene.size.height - 58)
        )
    }

    private func isWalkable(_ point: CGPoint, in scene: VillageScene) -> Bool {
        scene.walkableAreas.contains { $0.contains(point) }
    }

    private func markMoving(from oldPosition: CGPoint, to newPosition: CGPoint) {
        let deltaX = newPosition.x - oldPosition.x
        if abs(deltaX) > 1 {
            playerFacing = deltaX >= 0 ? 1 : -1
        }

        movementTick += 1
        let currentTick = movementTick
        isPlayerMoving = true

        Task {
            try? await Task.sleep(for: .milliseconds(180))
            if currentTick == movementTick {
                isPlayerMoving = false
            }
        }
    }

    private func distance(from first: CGPoint, to second: CGPoint) -> CGFloat {
        hypot(first.x - second.x, first.y - second.y)
    }
}

enum VillageDirection {
    case up
    case down
    case left
    case right

    var delta: CGSize {
        switch self {
        case .up:
            CGSize(width: 0, height: -1)
        case .down:
            CGSize(width: 0, height: 1)
        case .left:
            CGSize(width: -1, height: 0)
        case .right:
            CGSize(width: 1, height: 0)
        }
    }

    var icon: String {
        switch self {
        case .up:
            "chevron.up"
        case .down:
            "chevron.down"
        case .left:
            "chevron.left"
        case .right:
            "chevron.right"
        }
    }
}

struct WorldMapView: View {
    @StateObject private var game = VillageGameModel()
    @State private var mapZoom = CGFloat(1.28)
    @GestureState private var gestureZoom = CGFloat(1)

    private let minimumMapZoom = CGFloat(0.82)
    private let maximumMapZoom = CGFloat(2.2)

    private var activeMapZoom: CGFloat {
        clampedZoom(mapZoom * gestureZoom)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(red: 0.08, green: 0.13, blue: 0.11)
                    .ignoresSafeArea()

                GeometryReader { proxy in
                    let viewport = proxy.size
                    let zoom = activeMapZoom
                    let offset = cameraOffset(viewport: viewport, zoom: zoom)

                    VillageCanvas(game: game)
                        .frame(width: game.scene.size.width, height: game.scene.size.height)
                        .scaleEffect(zoom, anchor: .topLeading)
                        .offset(offset)
                        .frame(width: viewport.width, height: viewport.height)
                        .clipped()
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                .onChanged { value in
                                    game.movePlayer(to: scenePoint(from: value.location, viewport: viewport, zoom: zoom))
                                }
                        )
                        .simultaneousGesture(mapMagnificationGesture)
                        .animation(.easeOut(duration: 0.16), value: game.playerPosition)
                        .animation(.easeOut(duration: 0.20), value: zoom)
                        .onChange(of: game.sceneID) { _, _ in
                            mapZoom = game.scene.id == .village ? 1.28 : 1.12
                        }
                        .accessibilityLabel(game.scene.title)
                }

                VStack(spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        VillageHeader(scene: game.scene, statusText: game.statusText)

                        ZoomControls(
                            canZoomIn: activeMapZoom < maximumMapZoom,
                            canZoomOut: activeMapZoom > minimumMapZoom,
                            zoomIn: { mapZoom = clampedZoom(mapZoom + 0.16) },
                            zoomOut: { mapZoom = clampedZoom(mapZoom - 0.16) }
                        )
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)

                    Spacer()

                    VillageControls(
                        primaryTitle: game.primaryActionTitle,
                        canUsePrimary: game.canUsePrimaryAction,
                        moveVector: { game.move(vector: $0) },
                        usePrimary: game.usePrimaryAction
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Spanish Village")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $game.activeConversation) { character in
                ScholarPracticeView(character: character)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var mapMagnificationGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureZoom) { value, state, _ in
                state = value
            }
            .onEnded { value in
                mapZoom = clampedZoom(mapZoom * value)
            }
    }

    private func clampedZoom(_ value: CGFloat) -> CGFloat {
        min(max(value, minimumMapZoom), maximumMapZoom)
    }

    private func scenePoint(from viewportPoint: CGPoint, viewport: CGSize, zoom: CGFloat) -> CGPoint {
        let offset = cameraOffset(viewport: viewport, zoom: zoom)
        return CGPoint(
            x: (viewportPoint.x - offset.width) / zoom,
            y: (viewportPoint.y - offset.height) / zoom
        )
    }

    private func cameraOffset(viewport: CGSize, zoom: CGFloat) -> CGSize {
        let scaledScene = CGSize(
            width: game.scene.size.width * zoom,
            height: game.scene.size.height * zoom
        )

        let desired = CGSize(
            width: viewport.width / 2 - game.playerPosition.x * zoom,
            height: viewport.height / 2 - game.playerPosition.y * zoom
        )

        return CGSize(
            width: clampedCameraAxis(desired.width, viewport: viewport.width, content: scaledScene.width),
            height: clampedCameraAxis(desired.height, viewport: viewport.height, content: scaledScene.height)
        )
    }

    private func clampedCameraAxis(_ value: CGFloat, viewport: CGFloat, content: CGFloat) -> CGFloat {
        guard content > viewport else {
            return (viewport - content) / 2
        }

        return min(CGFloat(0), max(viewport - content, value))
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

private struct VillageCanvas: View {
    @ObservedObject var game: VillageGameModel

    var body: some View {
        ZStack {
            GameArtImage(game.scene.backgroundImageName)
                .resizable()
                .scaledToFill()
                .frame(width: game.scene.size.width, height: game.scene.size.height)
                .clipped()

            ForEach(game.scene.portals) { portal in
                PortalMarkerView(
                    portal: portal,
                    isNearby: game.nearbyPortal?.id == portal.id
                )
            }

            ForEach(game.scene.characters) { character in
                VillageCharacterView(
                    character: character,
                    isNearby: game.nearbyCharacter == character
                )
                .position(character.position)
            }

            VillagePlayerView(isMoving: game.isPlayerMoving, facing: game.playerFacing)
                .position(game.playerPosition)
                .animation(.spring(response: 0.24, dampingFraction: 0.86), value: game.playerPosition)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(game.scene.title)
    }
}

private struct PortalMarkerView: View {
    let portal: VillagePortal
    let isNearby: Bool

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: portal.icon)
                .font(.system(size: isNearby ? 24 : 19, weight: .black))
                .foregroundStyle(isNearby ? Color(red: 0.14, green: 0.14, blue: 0.09) : .white)
                .frame(width: isNearby ? 54 : 44, height: isNearby ? 54 : 44)
                .background(
                    Circle()
                        .fill(isNearby ? Color(red: 1.0, green: 0.84, blue: 0.36) : Color.black.opacity(0.48))
                        .stroke(Color.white.opacity(0.75), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.30), radius: 8, y: 4)

            Text(isNearby ? portal.actionTitle : portal.title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.black.opacity(0.55)))
        }
        .position(x: portal.frame.midX, y: portal.frame.midY)
        .animation(.spring(response: 0.24, dampingFraction: 0.82), value: isNearby)
        .accessibilityLabel(portal.actionTitle)
    }
}

private struct VillageCharacterView: View {
    let character: VillageCharacter
    let isNearby: Bool

    var body: some View {
        VStack(spacing: 5) {
            if isNearby {
                Text("Talk")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.12, green: 0.18, blue: 0.16))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color(red: 1.0, green: 0.86, blue: 0.37)))
                    .transition(.scale.combined(with: .opacity))
            }

            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.26))
                    .frame(width: 42, height: 12)
                    .offset(y: 36)

                GameArtImage(character.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: isNearby ? 70 : 64, height: isNearby ? 92 : 84)
                    .shadow(color: Color.black.opacity(0.30), radius: 7, y: 5)
            }

            Text(character.name)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.black.opacity(0.45)))
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isNearby)
        .accessibilityLabel("\(character.name), \(character.role)")
    }
}

private struct VillagePlayerView: View {
    let isMoving: Bool
    let facing: CGFloat
    @State private var bob = false

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.26))
                    .frame(width: 42, height: 12)
                    .offset(y: 36)

                GameArtImage("player_avatar")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 84)
                    .scaleEffect(x: facing, y: 1, anchor: .center)
                    .offset(y: isMoving && bob ? -5 : 0)
                    .shadow(color: Color.black.opacity(0.32), radius: 7, y: 5)
            }

            Text("You")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.black.opacity(0.48)))
        }
        .onAppear {
            bob = isMoving
        }
        .onChange(of: isMoving) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.16).repeatForever(autoreverses: true)) {
                    bob = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.10)) {
                    bob = false
                }
            }
        }
        .accessibilityLabel("Your character")
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
                    moveVector(CGSize(width: clamped.width / maxOffset, height: clamped.height / maxOffset))
                }
                .onEnded { _ in
                    knobOffset = .zero
                }
        )
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
