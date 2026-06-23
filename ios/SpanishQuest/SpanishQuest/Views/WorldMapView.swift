import SwiftUI
import UIKit

struct QuestStage: Identifiable {
    let id: String
    let number: Int
    let name: String
    let region: String
    let status: StageStatus
    let icon: String
    let thumbnailName: String
    let mapPosition: CGPoint
    let tint: Color

    var isUnlocked: Bool {
        status == .available
    }

    static let journey: [QuestStage] = [
        QuestStage(
            id: "forest-1",
            number: 1,
            name: "Forest of First Words",
            region: "Whisperwood",
            status: .available,
            icon: "tree.fill",
            thumbnailName: "forest_arena",
            mapPosition: CGPoint(x: 0.25, y: 0.76),
            tint: Color(red: 0.20, green: 0.64, blue: 0.34)
        ),
        QuestStage(
            id: "river-2",
            number: 2,
            name: "River Crossing",
            region: "Moonlit Ferry",
            status: .locked,
            icon: "water.waves",
            thumbnailName: "world_map_storybook",
            mapPosition: CGPoint(x: 0.42, y: 0.61),
            tint: Color(red: 0.21, green: 0.53, blue: 0.79)
        ),
        QuestStage(
            id: "mountain-3",
            number: 3,
            name: "Mountain Gate",
            region: "Stonepass",
            status: .locked,
            icon: "mountain.2.fill",
            thumbnailName: "world_map_storybook",
            mapPosition: CGPoint(x: 0.64, y: 0.41),
            tint: Color(red: 0.54, green: 0.52, blue: 0.60)
        ),
        QuestStage(
            id: "castle-4",
            number: 4,
            name: "Dark Castle",
            region: "Dragon Keep",
            status: .locked,
            icon: "building.columns.fill",
            thumbnailName: "world_map_storybook",
            mapPosition: CGPoint(x: 0.79, y: 0.20),
            tint: Color(red: 0.62, green: 0.20, blue: 0.26)
        )
    ]
}

enum StageStatus {
    case available
    case locked

    var label: String {
        switch self {
        case .available:
            "Ready"
        case .locked:
            "Locked"
        }
    }
}

struct WorldMapView: View {
    private let stages = QuestStage.journey
    private let minimumMapScale = CGFloat(0.5)
    private let maximumMapScale = CGFloat(2.6)

    @State private var mapScale = CGFloat(1)
    @GestureState private var gestureScale = CGFloat(1)

    private var activeMapScale: CGFloat {
        clampedMapScale(mapScale * gestureScale)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ArtImage("world_map_storybook")
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 16)
                    .overlay(Color.black.opacity(0.50))
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.46),
                        Color(red: 0.07, green: 0.09, blue: 0.10).opacity(0.68)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                GeometryReader { screenProxy in
                    mapPanel(height: max(CGFloat(620), screenProxy.size.height - 56))
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 18)
                }
            }
            .navigationTitle("Spanish Quest")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func mapPanel(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { proxy in
                let baseMapSide = max(proxy.size.width * 1.75, CGFloat(700))
                let mapSide = baseMapSide * activeMapScale
                let edgeInset = max(CGFloat(96), CGFloat(120) * activeMapScale)

                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    MapCanvas(stages: stages, side: mapSide)
                        .padding(edgeInset)
                }
                .simultaneousGesture(mapMagnificationGesture)
                .defaultScrollAnchor(.bottomLeading)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .background(Color.black.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 1.0, green: 0.78, blue: 0.38).opacity(0.42), lineWidth: 2)
                )
            }
            .frame(height: height)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.34))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Painted world map with forest, river, mountain, and castle stages")
    }

    private var mapMagnificationGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureScale) { value, state, _ in
                state = value
            }
            .onEnded { value in
                mapScale = clampedMapScale(mapScale * value)
            }
    }

    private func clampedMapScale(_ scale: CGFloat) -> CGFloat {
        min(max(scale, minimumMapScale), maximumMapScale)
    }
}

private struct MapCanvas: View {
    let stages: [QuestStage]
    let side: CGFloat

    var body: some View {
        ZStack {
            ArtImage("world_map_storybook")
                .resizable()
                .scaledToFit()
                .frame(width: side, height: side)
                .overlay(Color.black.opacity(0.08))

            LinearGradient(
                colors: [
                    Color.black.opacity(0.02),
                    Color.black.opacity(0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            QuestRoute(stages: stages)
                .stroke(
                    Color(red: 1.0, green: 0.84, blue: 0.46).opacity(0.78),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round, dash: [10, 9])
                )
                .shadow(color: .black.opacity(0.50), radius: 2, y: 1)

            MapStoryPin(
                imageName: "shadow_dragon_portrait",
                label: "Dragon",
                accent: Color(red: 0.80, green: 0.12, blue: 0.16)
            )
            .position(x: side * 0.88, y: side * 0.13)

            MapStoryPin(
                imageName: "princess_portrait",
                label: "Princess",
                accent: Color(red: 0.28, green: 0.50, blue: 0.92)
            )
            .position(x: side * 0.79, y: side * 0.16)

            HeroLocationBadge()
                .position(x: side * 0.15, y: side * 0.69)

            ForEach(stages) { stage in
                if stage.isUnlocked {
                    NavigationLink {
                        BattleView()
                    } label: {
                        MapStageNode(stage: stage)
                    }
                    .buttonStyle(.plain)
                    .position(x: side * stage.mapPosition.x, y: side * stage.mapPosition.y)
                } else {
                    MapStageNode(stage: stage)
                        .position(x: side * stage.mapPosition.x, y: side * stage.mapPosition.y)
                }
            }
        }
        .frame(width: side, height: side)
    }
}

private struct QuestRoute: Shape {
    let stages: [QuestStage]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = stages.first else {
            return path
        }

        path.move(to: point(for: first, in: rect))

        for stage in stages.dropFirst() {
            path.addLine(to: point(for: stage, in: rect))
        }

        return path
    }

    private func point(for stage: QuestStage, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + rect.width * stage.mapPosition.x,
            y: rect.minY + rect.height * stage.mapPosition.y
        )
    }
}

private struct MapStageNode: View {
    let stage: QuestStage

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                if stage.isUnlocked {
                    Circle()
                        .fill(stage.tint.opacity(0.28))
                        .frame(width: 108, height: 108)
                        .blur(radius: 10)
                }

                ArtImage(stage.thumbnailName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 82, height: 82)
                    .clipShape(Circle())
                    .saturation(stage.isUnlocked ? 1 : 0.45)
                    .brightness(stage.isUnlocked ? 0.02 : -0.12)
                    .shadow(color: stage.tint.opacity(stage.isUnlocked ? 0.88 : 0.24), radius: stage.isUnlocked ? 14 : 5)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                stage.tint.opacity(0.15),
                                Color.black.opacity(stage.isUnlocked ? 0.08 : 0.48)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 82, height: 82)

                Circle()
                    .stroke(Color.white.opacity(stage.isUnlocked ? 0.92 : 0.42), lineWidth: 3)
                    .frame(width: 82, height: 82)

                Circle()
                    .stroke(stage.tint.opacity(stage.isUnlocked ? 0.95 : 0.48), lineWidth: 5)
                    .frame(width: 92, height: 92)

                VStack(spacing: 2) {
                    Image(systemName: stage.isUnlocked ? stage.icon : "lock.fill")
                        .font(.system(size: 23, weight: .black))
                    Text("\(stage.number)")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.75), radius: 4, y: 1)
            }

            VStack(spacing: 1) {
                Text("Stage \(stage.number)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                Text(stage.status.label)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(stage.isUnlocked ? Color(red: 0.74, green: 1.0, blue: 0.54) : .white.opacity(0.58))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.black.opacity(0.56)))
        }
        .opacity(stage.isUnlocked ? 1 : 0.72)
        .accessibilityLabel("\(stage.name), \(stage.status.label)")
    }
}

private struct MapStoryPin: View {
    let imageName: String
    let label: String
    let accent: Color

    var body: some View {
        VStack(spacing: 3) {
            ArtImage(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(accent, lineWidth: 3)
                )
                .shadow(color: accent.opacity(0.70), radius: 9)

            Text(label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.black.opacity(0.62)))
        }
        .accessibilityLabel(label)
    }
}

private struct HeroLocationBadge: View {
    var body: some View {
        VStack(spacing: 3) {
            SpriteSheetFirstFrame(imageName: "hero_spritesheet", size: 50)
                .padding(4)
                .background(Circle().fill(Color(red: 0.11, green: 0.48, blue: 0.42)))
                .overlay(
                    Circle()
                        .stroke(Color(red: 0.72, green: 1.0, blue: 0.56), lineWidth: 3)
                )
                .shadow(color: Color(red: 0.42, green: 1.0, blue: 0.62).opacity(0.82), radius: 12)

            Text("Hero")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.black.opacity(0.62)))
        }
        .accessibilityLabel("Hero current location")
    }
}

private struct SpriteSheetFirstFrame: View {
    let imageName: String
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            ArtImage(imageName)
                .resizable()
                .interpolation(.none)
                .frame(width: size * 4, height: size * 4)
        }
        .frame(width: size, height: size, alignment: .topLeading)
        .clipShape(Circle())
    }
}

private struct ArtImage {
    private let image: Image

    init(_ name: String) {
        if let uiImage = UIImage(named: name) ?? UIImage(contentsOfFile: Bundle.main.path(forResource: name, ofType: "png") ?? "") {
            image = Image(uiImage: uiImage)
        } else {
            image = Image(systemName: "photo")
        }
    }

    func resizable() -> Image {
        image.resizable()
    }
}
