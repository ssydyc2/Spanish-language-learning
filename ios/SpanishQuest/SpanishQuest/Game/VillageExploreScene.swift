import SpriteKit
import UIKit

final class VillageExploreScene: SKScene {
    var onSceneChange: ((VillageScene) -> Void)?
    var onStatusChange: ((String) -> Void)?
    var onActionChange: ((String, Bool) -> Void)?
    var onPracticeRequested: ((VillageCharacter) -> Void)?

    private let cameraNode = SKCameraNode()
    private let worldNode = SKNode()
    private let mapNode = SKSpriteNode()
    private let playerNode = SKSpriteNode()
    private let playerShadow = SKShapeNode(ellipseOf: CGSize(width: 46, height: 14))

    private var portalNodes: [String: SKNode] = [:]
    private var characterNodes: [String: SKSpriteNode] = [:]
    private var characterLabels: [String: SKLabelNode] = [:]
    private var charactersByID: [String: VillageCharacter] = [:]
    private var sceneID: VillageSceneID = .village
    private var playerPosition = VillageScene.village.spawnPoint
    private var inputVector = CGSize.zero
    private var tapTarget: CGPoint?
    private var cameraScale: CGFloat = 0.78
    private var lastUpdateTime: TimeInterval = 0
    private var facing: CGFloat = 1
    private var activePortal: VillagePortal?
    private var activeCharacter: VillageCharacter?
    private var lastStatus = ""
    private var lastActionTitle = ""
    private var lastActionEnabled = false

    private let playerSpeed: CGFloat = 205
    private let tapArrivalDistance: CGFloat = 8
    private let portalRange: CGFloat = 105
    private let characterRange: CGFloat = 112

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        configureScene()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        scaleMode = .resizeFill
        configureScene()
    }

    override func didMove(to view: SKView) {
        view.ignoresSiblingOrder = true
        view.backgroundColor = UIColor(red: 0.07, green: 0.11, blue: 0.09, alpha: 1)
        updateCamera(force: true)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        updateCamera(force: true)
    }

    override func update(_ currentTime: TimeInterval) {
        let deltaTime: CGFloat
        if lastUpdateTime == 0 {
            deltaTime = 1 / 60
        } else {
            deltaTime = min(CGFloat(currentTime - lastUpdateTime), 1 / 20)
        }
        lastUpdateTime = currentTime

        updateMovement(deltaTime: deltaTime)
        updateSpriteAnimation(currentTime: currentTime)
        updateCamera(force: false)
        refreshInteractionState()
    }

    func setInputVector(_ vector: CGSize) {
        let length = hypot(vector.width, vector.height)
        guard length > 0.04 else {
            inputVector = .zero
            return
        }

        inputVector = CGSize(width: vector.width / length, height: vector.height / length)
        tapTarget = nil
    }

    func zoomIn() {
        cameraScale = max(0.56, cameraScale - 0.10)
        updateCamera(force: true)
    }

    func zoomOut() {
        cameraScale = min(1.34, cameraScale + 0.10)
        updateCamera(force: true)
    }

    func performPrimaryAction() {
        if let activeCharacter {
            onPracticeRequested?(activeCharacter)
            return
        }

        guard let activePortal else {
            setStatus("Move near a door or character first.")
            return
        }

        loadScene(activePortal.destination, spawn: activePortal.destinationSpawn)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateTapTarget(from: touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateTapTarget(from: touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateTapTarget(from: touches)
    }

    private func configureScene() {
        guard children.isEmpty else {
            return
        }

        backgroundColor = UIColor(red: 0.07, green: 0.11, blue: 0.09, alpha: 1)
        camera = cameraNode
        addChild(worldNode)
        addChild(cameraNode)

        mapNode.anchorPoint = CGPoint(x: 0, y: 0)
        mapNode.zPosition = -50
        worldNode.addChild(mapNode)

        playerShadow.fillColor = UIColor.black.withAlphaComponent(0.28)
        playerShadow.strokeColor = .clear
        playerShadow.zPosition = 19
        worldNode.addChild(playerShadow)

        let texture = texture(named: "player_avatar")
        playerNode.texture = texture
        playerNode.anchorPoint = CGPoint(x: 0.5, y: 0.08)
        playerNode.size = fittedSize(for: texture, height: 108)
        playerNode.zPosition = 30
        worldNode.addChild(playerNode)

        loadScene(.village, spawn: VillageScene.village.spawnPoint)
    }

    private func loadScene(_ id: VillageSceneID, spawn: CGPoint) {
        sceneID = id
        let nextScene = VillageScene.scene(for: id)
        playerPosition = clamp(spawn, in: nextScene)
        inputVector = .zero
        tapTarget = nil
        activePortal = nil
        activeCharacter = nil
        cameraScale = id == .village ? 0.78 : 0.70

        mapNode.texture = texture(named: nextScene.backgroundImageName)
        mapNode.size = nextScene.size
        removeSceneContent()
        buildPortals(in: nextScene)
        buildCharacters(in: nextScene)
        positionPlayer(animated: false)
        updateCamera(force: true)
        refreshInteractionState(force: true)
        onSceneChange?(nextScene)
        setStatus(statusText(for: nextScene))
    }

    private func removeSceneContent() {
        portalNodes.values.forEach { $0.removeFromParent() }
        characterNodes.values.forEach { $0.removeFromParent() }
        characterLabels.values.forEach { $0.removeFromParent() }
        portalNodes.removeAll()
        characterNodes.removeAll()
        characterLabels.removeAll()
        charactersByID.removeAll()
    }

    private func buildPortals(in scene: VillageScene) {
        for portal in scene.portals {
            let marker = SKNode()
            marker.position = skPoint(fromTopLeft: CGPoint(x: portal.frame.midX, y: portal.frame.midY), in: scene)
            marker.zPosition = 80

            let circle = SKShapeNode(circleOfRadius: 23)
            circle.name = "portalCircle"
            circle.fillColor = UIColor.black.withAlphaComponent(0.46)
            circle.strokeColor = UIColor.white.withAlphaComponent(0.72)
            circle.lineWidth = 2
            marker.addChild(circle)

            let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            label.name = "portalLabel"
            label.text = portal.title
            label.fontSize = 13
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: 0, y: -38)
            marker.addChild(label)

            worldNode.addChild(marker)
            portalNodes[portal.id] = marker
        }
    }

    private func buildCharacters(in scene: VillageScene) {
        for character in scene.characters {
            let texture = texture(named: character.imageName)
            let node = SKSpriteNode(texture: texture)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.08)
            node.position = skPoint(fromTopLeft: character.position, in: scene)
            node.size = fittedSize(for: texture, height: 106)
            node.zPosition = zPosition(for: character.position)

            let shadow = SKShapeNode(ellipseOf: CGSize(width: 44, height: 13))
            shadow.fillColor = UIColor.black.withAlphaComponent(0.24)
            shadow.strokeColor = .clear
            shadow.zPosition = -1
            node.addChild(shadow)

            let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            label.text = character.name
            label.fontSize = 15
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: 0, y: 100)
            label.zPosition = 95

            let labelBackground = SKShapeNode(rectOf: CGSize(width: 84, height: 26), cornerRadius: 13)
            labelBackground.fillColor = UIColor.black.withAlphaComponent(0.48)
            labelBackground.strokeColor = .clear
            labelBackground.zPosition = -1
            label.addChild(labelBackground)

            worldNode.addChild(node)
            node.addChild(label)
            characterNodes[character.id] = node
            characterLabels[character.id] = label
            charactersByID[character.id] = character
        }
    }

    private func updateMovement(deltaTime: CGFloat) {
        if inputVector != .zero {
            move(by: CGSize(
                width: inputVector.width * playerSpeed * deltaTime,
                height: inputVector.height * playerSpeed * deltaTime
            ))
            return
        }

        guard let tapTarget else {
            return
        }

        let delta = CGSize(width: tapTarget.x - playerPosition.x, height: tapTarget.y - playerPosition.y)
        let distance = hypot(delta.width, delta.height)
        guard distance > tapArrivalDistance else {
            self.tapTarget = nil
            return
        }

        let step = min(playerSpeed * deltaTime, distance)
        move(by: CGSize(width: delta.width / distance * step, height: delta.height / distance * step))
    }

    private func move(by delta: CGSize) {
        guard delta != .zero else {
            return
        }

        let scene = VillageScene.scene(for: sceneID)
        let proposed = clamp(
            CGPoint(x: playerPosition.x + delta.width, y: playerPosition.y + delta.height),
            in: scene
        )

        if isWalkable(proposed, in: scene) {
            commitMove(to: proposed)
            return
        }

        let horizontal = clamp(CGPoint(x: playerPosition.x + delta.width, y: playerPosition.y), in: scene)
        if isWalkable(horizontal, in: scene) {
            commitMove(to: horizontal)
            return
        }

        let vertical = clamp(CGPoint(x: playerPosition.x, y: playerPosition.y + delta.height), in: scene)
        if isWalkable(vertical, in: scene) {
            commitMove(to: vertical)
            return
        }

        setStatus(scene.id == .village ? "Stay on the village paths." : "Walk through the open floor area.")
    }

    private func commitMove(to nextPosition: CGPoint) {
        let deltaX = nextPosition.x - playerPosition.x
        if abs(deltaX) > 0.5 {
            facing = deltaX > 0 ? 1 : -1
        }

        playerPosition = nextPosition
        positionPlayer(animated: true)
    }

    private func positionPlayer(animated: Bool) {
        let scene = VillageScene.scene(for: sceneID)
        let skPosition = skPoint(fromTopLeft: playerPosition, in: scene)
        let actionDuration = animated ? 0.06 : 0
        playerNode.removeAction(forKey: "move")
        playerNode.xScale = abs(playerNode.xScale) * facing
        playerNode.zPosition = zPosition(for: playerPosition)
        playerNode.run(.move(to: skPosition, duration: actionDuration), withKey: "move")
        playerShadow.position = CGPoint(x: skPosition.x, y: skPosition.y - 7)
        playerShadow.zPosition = playerNode.zPosition - 1
    }

    private func updateSpriteAnimation(currentTime: TimeInterval) {
        let isMoving = inputVector != .zero || tapTarget != nil
        let bob = isMoving ? sin(currentTime * 15) * 4 : 0
        playerNode.position.y = skPoint(fromTopLeft: playerPosition, in: VillageScene.scene(for: sceneID)).y + bob
    }

    private func updateCamera(force: Bool) {
        let scene = VillageScene.scene(for: sceneID)
        let playerScenePosition = skPoint(fromTopLeft: playerPosition, in: scene)
        cameraNode.setScale(cameraScale)

        let visibleWidth = size.width * cameraScale
        let visibleHeight = size.height * cameraScale
        let x = clampedCameraValue(playerScenePosition.x, content: scene.size.width, visible: visibleWidth)
        let y = clampedCameraValue(playerScenePosition.y, content: scene.size.height, visible: visibleHeight)
        let target = CGPoint(x: x, y: y)

        if force {
            cameraNode.position = target
        } else {
            let blend: CGFloat = 0.18
            cameraNode.position = CGPoint(
                x: cameraNode.position.x + (target.x - cameraNode.position.x) * blend,
                y: cameraNode.position.y + (target.y - cameraNode.position.y) * blend
            )
        }
    }

    private func refreshInteractionState(force: Bool = false) {
        let scene = VillageScene.scene(for: sceneID)
        activeCharacter = scene.characters.first { distance(playerPosition, $0.position) <= characterRange }
        activePortal = scene.portals.first { $0.frame.insetBy(dx: -portalRange, dy: -portalRange).contains(playerPosition) }

        if let activeCharacter {
            highlightCharacter(activeCharacter.id, isActive: true)
            highlightPortals(activeID: nil)
            publishAction(title: "Talk", enabled: true, force: force)
            setStatus("You are near \(activeCharacter.name). Tap Talk to practice Spanish.", force: force)
        } else if let activePortal {
            highlightCharacter(nil, isActive: false)
            highlightPortals(activeID: activePortal.id)
            publishAction(title: activePortal.actionTitle, enabled: true, force: force)
            setStatus("You are near \(activePortal.title). Tap \(activePortal.actionTitle).", force: force)
        } else {
            highlightCharacter(nil, isActive: false)
            highlightPortals(activeID: nil)
            publishAction(title: "Explore", enabled: false, force: force)
            if force || lastStatus.isEmpty {
                setStatus(statusText(for: scene), force: true)
            }
        }
    }

    private func highlightPortals(activeID: String?) {
        for (id, node) in portalNodes {
            let isActive = id == activeID
            node.setScale(isActive ? 1.18 : 1)
            if let circle = node.childNode(withName: "portalCircle") as? SKShapeNode {
                circle.fillColor = isActive
                    ? UIColor(red: 1.0, green: 0.78, blue: 0.25, alpha: 0.95)
                    : UIColor.black.withAlphaComponent(0.46)
                circle.strokeColor = UIColor.white.withAlphaComponent(isActive ? 0.92 : 0.72)
            }
        }
    }

    private func highlightCharacter(_ activeID: String?, isActive: Bool) {
        for (id, node) in characterNodes {
            let shouldHighlight = isActive && id == activeID
            node.setScale(shouldHighlight ? 1.08 : 1)
            characterLabels[id]?.text = shouldHighlight ? "Talk" : charactersByID[id]?.name ?? "NPC"
        }
    }

    private func publishAction(title: String, enabled: Bool, force: Bool) {
        guard force || title != lastActionTitle || enabled != lastActionEnabled else {
            return
        }

        lastActionTitle = title
        lastActionEnabled = enabled
        onActionChange?(title, enabled)
    }

    private func setStatus(_ text: String, force: Bool = false) {
        guard force || text != lastStatus else {
            return
        }

        lastStatus = text
        onStatusChange?(text)
    }

    private func updateTapTarget(from touches: Set<UITouch>) {
        guard inputVector == .zero, let touch = touches.first else {
            return
        }

        let location = touch.location(in: self)
        tapTarget = topLeftPoint(from: location, in: VillageScene.scene(for: sceneID))
    }

    private func texture(named name: String) -> SKTexture {
        let bundlePath = Bundle.main.path(forResource: name, ofType: "png")
        let artPath = Bundle.main.path(forResource: name, ofType: "png", inDirectory: "Resources/Art")
        let image = UIImage(named: name)
            ?? UIImage(contentsOfFile: bundlePath ?? "")
            ?? UIImage(contentsOfFile: artPath ?? "")
            ?? UIImage()
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private func fittedSize(for texture: SKTexture, height: CGFloat) -> CGSize {
        let size = texture.size()
        guard size.height > 0 else {
            return CGSize(width: height * 0.45, height: height)
        }

        return CGSize(width: height * size.width / size.height, height: height)
    }

    private func skPoint(fromTopLeft point: CGPoint, in scene: VillageScene) -> CGPoint {
        CGPoint(x: point.x, y: scene.size.height - point.y)
    }

    private func topLeftPoint(from point: CGPoint, in scene: VillageScene) -> CGPoint {
        CGPoint(x: point.x, y: scene.size.height - point.y)
    }

    private func clamp(_ point: CGPoint, in scene: VillageScene) -> CGPoint {
        CGPoint(
            x: min(max(48, point.x), scene.size.width - 48),
            y: min(max(58, point.y), scene.size.height - 58)
        )
    }

    private func clampedCameraValue(_ value: CGFloat, content: CGFloat, visible: CGFloat) -> CGFloat {
        guard content > visible else {
            return content / 2
        }

        return min(max(visible / 2, value), content - visible / 2)
    }

    private func isWalkable(_ point: CGPoint, in scene: VillageScene) -> Bool {
        scene.walkableAreas.contains { $0.contains(point) }
    }

    private func distance(_ first: CGPoint, _ second: CGPoint) -> CGFloat {
        hypot(first.x - second.x, first.y - second.y)
    }

    private func zPosition(for point: CGPoint) -> CGFloat {
        20 + point.y / 10
    }

    private func statusText(for scene: VillageScene) -> String {
        switch scene.id {
        case .village:
            return "Explore the village. School, cafe, and library are enterable."
        case .school:
            return "This classroom can host future lessons. Exit near the bottom door."
        case .cafe:
            return "Cafe conversations can be added here later. Exit through the open door."
        case .library:
            return "Walk close to the scholar to start Spanish practice. Exit near the bottom."
        }
    }
}
