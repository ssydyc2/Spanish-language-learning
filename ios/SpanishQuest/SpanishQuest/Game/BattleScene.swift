import SpriteKit

final class BattleScene: SKScene {
    private let hero = SKSpriteNode()
    private let monster = SKSpriteNode()
    private let background = SKSpriteNode(imageNamed: "forest_arena")

    private var heroIdle: [SKTexture] = []
    private var heroAttack: [SKTexture] = []
    private var heroHurt: [SKTexture] = []
    private var heroDodge: [SKTexture] = []
    private var monsterIdle: [SKTexture] = []
    private var monsterAttack: [SKTexture] = []
    private var monsterHurt: [SKTexture] = []
    private var monsterDefeat: [SKTexture] = []
    private var hasConfiguredScene = false

    override func didMove(to view: SKView) {
        scaleMode = .resizeFill
        configureSceneIfNeeded()
        layoutNodes()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        layoutNodes()
    }

    func apply(event: BattleAnimationEvent) {
        configureSceneIfNeeded()

        switch event.kind {
        case .resetBattle:
            resetBattle()
        case .playerAttack(let isHalfPower):
            playerAttack(isHalfPower: isHalfPower)
        case .playerMiss:
            playerMiss()
        case .playerDodge:
            playerDodge()
        case .playerBlock:
            playerBlock()
        case .playerHurt:
            playerHurt()
        case .monsterAttack:
            monsterAttackAction()
        case .monsterHurt:
            monsterHurtAction()
        case .monsterDefeated:
            monsterDefeated()
        }
    }

    private func configureSceneIfNeeded() {
        guard !hasConfiguredScene else {
            return
        }

        hasConfiguredScene = true
        background.zPosition = -10
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addChild(background)

        heroIdle = frames(sheet: "hero_spritesheet", row: 0)
        heroAttack = frames(sheet: "hero_spritesheet", row: 1)
        heroHurt = frames(sheet: "hero_spritesheet", row: 2)
        heroDodge = frames(sheet: "hero_spritesheet", row: 3)
        monsterIdle = frames(sheet: "monster_spritesheet", row: 0)
        monsterAttack = frames(sheet: "monster_spritesheet", row: 1)
        monsterHurt = frames(sheet: "monster_spritesheet", row: 2)
        monsterDefeat = frames(sheet: "monster_spritesheet", row: 3)

        hero.texture = heroIdle.first
        hero.size = CGSize(width: 112, height: 112)
        hero.zPosition = 5
        addChild(hero)

        monster.texture = monsterIdle.first
        monster.size = CGSize(width: 118, height: 118)
        monster.zPosition = 5
        addChild(monster)

        runIdleLoops()
    }

    private func layoutNodes() {
        guard size.width > 0, size.height > 0 else {
            return
        }

        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        let imageAspect = background.texture.map { $0.size().width / $0.size().height } ?? 16 / 9
        let sceneAspect = size.width / size.height
        if sceneAspect > imageAspect {
            background.size = CGSize(width: size.width, height: size.width / imageAspect)
        } else {
            background.size = CGSize(width: size.height * imageAspect, height: size.height)
        }

        hero.position = CGPoint(x: size.width * 0.28, y: size.height * 0.31)
        monster.position = CGPoint(x: size.width * 0.72, y: size.height * 0.59)
    }

    private func frames(sheet name: String, row: Int) -> [SKTexture] {
        let base = SKTexture(imageNamed: name)
        base.filteringMode = .nearest

        return (0..<4).map { column in
            let rect = CGRect(
                x: CGFloat(column) / 4,
                y: 1 - CGFloat(row + 1) / 4,
                width: 1 / 4,
                height: 1 / 4
            )
            let texture = SKTexture(rect: rect, in: base)
            texture.filteringMode = .nearest
            return texture
        }
    }

    private func runIdleLoops() {
        hero.removeAction(forKey: "idle")
        monster.removeAction(forKey: "idle")

        hero.run(
            .repeatForever(.animate(with: heroIdle, timePerFrame: 0.22, resize: false, restore: true)),
            withKey: "idle"
        )
        monster.run(
            .repeatForever(.animate(with: monsterIdle, timePerFrame: 0.24, resize: false, restore: true)),
            withKey: "idle"
        )
    }

    private func resetBattle() {
        hero.removeAllActions()
        monster.removeAllActions()

        hero.alpha = 1
        hero.xScale = abs(hero.xScale)
        hero.yScale = abs(hero.yScale)
        hero.zRotation = 0
        hero.colorBlendFactor = 0
        hero.texture = heroIdle.first
        hero.size = CGSize(width: 112, height: 112)

        monster.alpha = 1
        monster.xScale = abs(monster.xScale)
        monster.yScale = abs(monster.yScale)
        monster.zRotation = 0
        monster.colorBlendFactor = 0
        monster.texture = monsterIdle.first
        monster.size = CGSize(width: 118, height: 118)

        layoutNodes()
        runIdleLoops()
    }

    private func playerAttack(isHalfPower: Bool) {
        let start = hero.position
        let strikePoint = CGPoint(
            x: monster.position.x - monster.size.width * 0.62,
            y: monster.position.y - monster.size.height * 0.28
        )
        hero.removeAction(forKey: "idle")

        let moveOut = SKAction.move(to: strikePoint, duration: 0.24)
        moveOut.timingMode = .easeOut
        let swing = SKAction.animate(with: heroAttack, timePerFrame: 0.08, resize: false, restore: false)
        let moveBack = SKAction.move(to: start, duration: 0.24)
        moveBack.timingMode = .easeInEaseOut
        let hit = SKAction.run { [weak self] in
            self?.monsterHurtAction(strong: !isHalfPower)
        }
        let recover = SKAction.run { [weak self] in
            self?.runIdleLoops()
        }

        hero.run(.sequence([.group([moveOut, swing]), hit, moveBack, recover]))
    }

    private func playerMiss() {
        let start = hero.position
        hero.removeAction(forKey: "idle")
        hero.run(
            .sequence([
                .move(to: CGPoint(x: start.x + 46, y: start.y + 18), duration: 0.15),
                .rotate(byAngle: -0.12, duration: 0.08),
                .rotate(toAngle: 0, duration: 0.08),
                .move(to: start, duration: 0.18),
                .run { [weak self] in self?.runIdleLoops() }
            ])
        )
    }

    private func playerDodge() {
        let heroStart = hero.position
        let monsterStart = monster.position
        let strikePoint = CGPoint(
            x: heroStart.x + hero.size.width * 0.58,
            y: heroStart.y + hero.size.height * 0.28
        )
        hero.removeAction(forKey: "idle")
        monster.removeAction(forKey: "idle")

        let monsterOut = SKAction.move(to: strikePoint, duration: 0.2)
        monsterOut.timingMode = .easeOut
        let monsterBack = SKAction.move(to: monsterStart, duration: 0.22)
        monsterBack.timingMode = .easeInEaseOut

        hero.run(
            .sequence([
                .group([
                    .animate(with: heroDodge, timePerFrame: 0.07, resize: false, restore: false),
                    .move(to: CGPoint(x: heroStart.x - 62, y: heroStart.y - 34), duration: 0.16),
                    .fadeAlpha(to: 0.55, duration: 0.12)
                ]),
                .group([
                    .move(to: heroStart, duration: 0.18),
                    .fadeAlpha(to: 1, duration: 0.18)
                ]),
                .run { [weak self] in self?.runIdleLoops() }
            ])
        )
        monster.run(
            .sequence([
                .group([
                    .animate(with: monsterAttack, timePerFrame: 0.08, resize: false, restore: false),
                    monsterOut
                ]),
                monsterBack
            ])
        )
    }

    private func playerBlock() {
        let heroStart = hero.position
        let monsterStart = monster.position
        let strikePoint = CGPoint(
            x: heroStart.x + hero.size.width * 0.62,
            y: heroStart.y + hero.size.height * 0.3
        )
        hero.removeAction(forKey: "idle")
        monster.removeAction(forKey: "idle")

        let monsterOut = SKAction.move(to: strikePoint, duration: 0.2)
        monsterOut.timingMode = .easeOut
        let monsterBack = SKAction.move(to: monsterStart, duration: 0.22)
        monsterBack.timingMode = .easeInEaseOut

        monster.run(
            .sequence([
                .group([
                    .animate(with: monsterAttack, timePerFrame: 0.08, resize: false, restore: false),
                    monsterOut
                ]),
                .run { [weak self] in self?.playerHurt(strength: 0.5) },
                monsterBack,
                .run { [weak self] in self?.runIdleLoops() }
            ])
        )
    }

    private func playerHurt(strength: CGFloat = 1) {
        hero.removeAction(forKey: "idle")
        hero.run(
            .sequence([
                .animate(with: heroHurt, timePerFrame: 0.09, resize: false, restore: false),
                flash(node: hero, color: .red, strength: strength),
                .run { [weak self] in self?.runIdleLoops() }
            ])
        )
    }

    private func monsterAttackAction() {
        let start = monster.position
        let strikePoint = CGPoint(
            x: hero.position.x + hero.size.width * 0.62,
            y: hero.position.y + hero.size.height * 0.3
        )
        monster.removeAction(forKey: "idle")

        let moveOut = SKAction.move(to: strikePoint, duration: 0.24)
        moveOut.timingMode = .easeOut
        let moveBack = SKAction.move(to: start, duration: 0.24)
        moveBack.timingMode = .easeInEaseOut

        monster.run(
            .sequence([
                .group([
                    .animate(with: monsterAttack, timePerFrame: 0.08, resize: false, restore: false),
                    moveOut
                ]),
                .run { [weak self] in self?.playerHurt() },
                moveBack,
                .run { [weak self] in self?.runIdleLoops() }
            ])
        )
    }

    private func monsterHurtAction(strong: Bool = true) {
        monster.removeAction(forKey: "idle")
        monster.run(
            .sequence([
                .animate(with: monsterHurt, timePerFrame: 0.08, resize: false, restore: false),
                flash(node: monster, color: .red, strength: strong ? 0.85 : 0.45),
                shake(node: monster, distance: strong ? 10 : 5),
                .run { [weak self] in self?.runIdleLoops() }
            ])
        )
    }

    private func monsterDefeated() {
        monster.removeAllActions()
        monster.run(
            .sequence([
                .animate(with: monsterDefeat, timePerFrame: 0.11, resize: false, restore: false),
                .group([
                    .fadeAlpha(to: 0.25, duration: 0.35),
                    .scale(to: 0.82, duration: 0.35)
                ])
            ])
        )
    }

    private func flash(node: SKSpriteNode, color: UIColor, strength: CGFloat) -> SKAction {
        .sequence([
            .colorize(with: color, colorBlendFactor: strength, duration: 0.08),
            .colorize(withColorBlendFactor: 0, duration: 0.12)
        ])
    }

    private func shake(node: SKSpriteNode, distance: CGFloat) -> SKAction {
        let start = node.position
        return .sequence([
            .move(to: CGPoint(x: start.x + distance, y: start.y), duration: 0.04),
            .move(to: CGPoint(x: start.x - distance, y: start.y), duration: 0.05),
            .move(to: start, duration: 0.04)
        ])
    }
}
