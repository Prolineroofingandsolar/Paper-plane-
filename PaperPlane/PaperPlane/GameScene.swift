import SpriteKit
import SwiftUI

class GameScene: SKScene, SKPhysicsContactDelegate {

    weak var gameState: GameState?

    // Nodes
    private var plane: SKSpriteNode!
    private var background: SKSpriteNode!
    private var groundTop: SKNode!
    private var groundBottom: SKNode!

    // Game config
    private let planeX: CGFloat = 120
    private let gapSize: CGFloat = 220
    private let pipeWidth: CGFloat = 70
    private let pipeSpeed: CGFloat = 250
    private var spawnInterval: TimeInterval = 2.2
    private var gravity: CGFloat = -900

    // State
    private var isRunning = false
    private var isTapping = false
    private var tapForce: CGFloat = 0

    // Physics categories
    private let planeCat: UInt32 = 0x1 << 0
    private let obstacleCat: UInt32 = 0x1 << 1
    private let scoreCat: UInt32 = 0x1 << 2
    private let boundsCat: UInt32 = 0x1 << 3

    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        setupBackground()
        setupBounds()
        setupPlane()
    }

    // MARK: - Setup

    private func setupBackground() {
        let gradient = SKShapeNode(rect: frame)
        gradient.fillColor = .clear
        gradient.strokeColor = .clear

        // Sky gradient using two rects
        let skyTop = SKSpriteNode(color: UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1), size: CGSize(width: size.width, height: size.height * 0.7))
        skyTop.position = CGPoint(x: size.width / 2, y: size.height * 0.65)
        addChild(skyTop)

        let skyBottom = SKSpriteNode(color: UIColor(red: 0.6, green: 0.85, blue: 1.0, alpha: 1), size: CGSize(width: size.width, height: size.height * 0.4))
        skyBottom.position = CGPoint(x: size.width / 2, y: size.height * 0.2)
        addChild(skyBottom)

        // Clouds
        for i in 0..<5 {
            addCloud(x: CGFloat(i) * size.width / 4 + 60)
        }
    }

    private func addCloud(x: CGFloat) {
        let cloud = SKNode()
        let y = CGFloat.random(in: size.height * 0.4 ... size.height * 0.85)
        cloud.position = CGPoint(x: x, y: y)

        for offset in [CGPoint.zero, CGPoint(x: 30, y: 10), CGPoint(x: -25, y: 8)] {
            let circle = SKShapeNode(circleOfRadius: CGFloat.random(in: 25...45))
            circle.fillColor = .white
            circle.strokeColor = .clear
            circle.alpha = 0.85
            circle.position = offset
            cloud.addChild(circle)
        }
        cloud.zPosition = 1
        addChild(cloud)
    }

    private func setupBounds() {
        // Top bound
        groundTop = SKNode()
        groundTop.position = CGPoint(x: size.width / 2, y: size.height)
        let topBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width, height: 10))
        topBody.isDynamic = false
        topBody.categoryBitMask = boundsCat
        topBody.contactTestBitMask = planeCat
        groundTop.physicsBody = topBody
        addChild(groundTop)

        // Bottom bound
        groundBottom = SKNode()
        groundBottom.position = CGPoint(x: size.width / 2, y: 0)
        let bottomBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width, height: 10))
        bottomBody.isDynamic = false
        bottomBody.categoryBitMask = boundsCat
        bottomBody.contactTestBitMask = planeCat
        groundBottom.physicsBody = bottomBody
        addChild(groundBottom)
    }

    private func setupPlane() {
        plane = SKSpriteNode()
        plane.size = CGSize(width: 60, height: 35)

        // Draw plane using shapes
        let body = SKShapeNode()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 30, y: 0))
        path.addLine(to: CGPoint(x: -30, y: 12))
        path.addLine(to: CGPoint(x: -20, y: 0))
        path.addLine(to: CGPoint(x: -30, y: -10))
        path.close()
        body.path = path.cgPath
        body.fillColor = .white
        body.strokeColor = UIColor(white: 0.8, alpha: 1)
        body.lineWidth = 1.5

        // Wing
        let wing = SKShapeNode()
        let wingPath = UIBezierPath()
        wingPath.move(to: CGPoint(x: 0, y: 0))
        wingPath.addLine(to: CGPoint(x: -10, y: 22))
        wingPath.addLine(to: CGPoint(x: -22, y: 4))
        wingPath.close()
        wing.path = wingPath.cgPath
        wing.fillColor = UIColor(white: 0.9, alpha: 1)
        wing.strokeColor = UIColor(white: 0.75, alpha: 1)
        wing.lineWidth = 1

        plane.addChild(body)
        plane.addChild(wing)
        plane.position = CGPoint(x: planeX, y: size.height / 2)
        plane.zPosition = 10

        let planeBody = SKPhysicsBody(rectangleOf: CGSize(width: 50, height: 28))
        planeBody.isDynamic = true
        planeBody.affectedByGravity = false
        planeBody.categoryBitMask = planeCat
        planeBody.contactTestBitMask = obstacleCat | boundsCat
        planeBody.collisionBitMask = 0
        planeBody.restitution = 0
        plane.physicsBody = planeBody

        addChild(plane)
    }

    // MARK: - Game Flow

    private func startGame() {
        isRunning = true
        DispatchQueue.main.async { self.gameState?.hasStarted = true }
        spawnPipes()
    }

    private func spawnPipes() {
        guard isRunning else { return }

        let gapCenter = CGFloat.random(in: size.height * 0.25 ... size.height * 0.75)
        let topHeight = size.height - (gapCenter + gapSize / 2)
        let bottomHeight = gapCenter - gapSize / 2

        // Top pipe
        let topPipe = makeCloudPipe(height: topHeight)
        topPipe.position = CGPoint(x: size.width + pipeWidth / 2, y: size.height - topHeight / 2)
        addChild(topPipe)
        topPipe.run(SKAction.sequence([
            SKAction.moveBy(x: -(size.width + pipeWidth + 20), y: 0, duration: (size.width + pipeWidth + 20) / pipeSpeed),
            SKAction.removeFromParent()
        ]))

        // Bottom pipe
        let bottomPipe = makeCloudPipe(height: bottomHeight)
        bottomPipe.position = CGPoint(x: size.width + pipeWidth / 2, y: bottomHeight / 2)
        addChild(bottomPipe)
        bottomPipe.run(SKAction.sequence([
            SKAction.moveBy(x: -(size.width + pipeWidth + 20), y: 0, duration: (size.width + pipeWidth + 20) / pipeSpeed),
            SKAction.removeFromParent()
        ]))

        // Score sensor
        let sensor = SKNode()
        sensor.position = CGPoint(x: size.width + pipeWidth / 2 + 35, y: size.height / 2)
        let sensorBody = SKPhysicsBody(rectangleOf: CGSize(width: 10, height: size.height))
        sensorBody.isDynamic = false
        sensorBody.categoryBitMask = scoreCat
        sensorBody.contactTestBitMask = planeCat
        sensorBody.collisionBitMask = 0
        sensor.physicsBody = sensorBody
        sensor.zPosition = 5
        addChild(sensor)
        sensor.run(SKAction.sequence([
            SKAction.moveBy(x: -(size.width + pipeWidth + 60), y: 0, duration: (size.width + pipeWidth + 60) / pipeSpeed),
            SKAction.removeFromParent()
        ]))

        let wait = SKAction.wait(forDuration: spawnInterval)
        run(SKAction.sequence([wait, SKAction.run { [weak self] in self?.spawnPipes() }]))
    }

    private func makeCloudPipe(height: CGFloat) -> SKNode {
        let node = SKNode()
        node.zPosition = 3

        let rect = SKShapeNode(rectOf: CGSize(width: pipeWidth, height: height), cornerRadius: 8)
        rect.fillColor = UIColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1)
        rect.strokeColor = UIColor(red: 0.7, green: 0.85, blue: 0.95, alpha: 1)
        rect.lineWidth = 2
        node.addChild(rect)

        let body = SKPhysicsBody(rectangleOf: CGSize(width: pipeWidth, height: height))
        body.isDynamic = false
        body.categoryBitMask = obstacleCat
        body.contactTestBitMask = planeCat
        node.physicsBody = body

        return node
    }

    private func endGame() {
        isRunning = false
        removeAllActions()
        plane.physicsBody?.velocity = .zero

        // Shake effect
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -10, y: 0, duration: 0.05),
            SKAction.moveBy(x: 20, y: 0, duration: 0.05),
            SKAction.moveBy(x: -10, y: 0, duration: 0.05)
        ])
        plane.run(shake)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.gameState?.triggerGameOver()
        }
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        guard isRunning, let body = plane.physicsBody else { return }

        let gravityVelocity: CGFloat = isTapping ? 450 : gravity
        let currentVY = body.velocity.dy
        let targetVY = gravityVelocity
        body.velocity.dy = currentVY + (targetVY - currentVY) * 0.15

        // Clamp velocity
        body.velocity.dy = max(-600, min(600, body.velocity.dy))

        // Tilt plane based on velocity
        let tilt = atan2(Double(body.velocity.dy), 350.0)
        plane.zRotation = CGFloat(tilt * 0.8)

        // Keep in bounds
        if plane.position.y > size.height - 20 || plane.position.y < 20 {
            endGame()
        }
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isRunning && !(gameState?.isGameOver ?? false) {
            startGame()
        }
        isTapping = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTapping = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTapping = false
    }

    // MARK: - Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let masks = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if masks == planeCat | scoreCat {
            DispatchQueue.main.async { self.gameState?.addPoint() }
            // Remove sensor so it only scores once
            if contact.bodyA.categoryBitMask == scoreCat {
                contact.bodyA.node?.removeFromParent()
            } else {
                contact.bodyB.node?.removeFromParent()
            }
        } else if masks == planeCat | obstacleCat || masks == planeCat | boundsCat {
            if isRunning { endGame() }
        }
    }

    // MARK: - Scene reset

    override func willMove(from view: SKView) {
        removeAllChildren()
        removeAllActions()
    }
}
