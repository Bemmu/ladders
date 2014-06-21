import flash.geom.*;
import flash.display.*;
import box2D.dynamics.*;
import box2D.dynamics.joints.*;
import box2D.common.math.*;
import box2D.collision.shapes.*;

class StickMan extends GameObject {

	// If holding on to a ladder, this joint connects him to it.
	var ladderJoint:B2Joint = null;
	var climbSpeed = 1;
	var jumpTicks = 5;
	var canStillJumpTicks = 5; // countdown for how long can still continue jumping

	override public function new(tileX:Float, tileY:Float, screenScale:Float, world:B2World) {
		super(tileX, tileY, screenScale, world);
		frame = 1;

		var bodyDef = new B2BodyDef();
		bodyDef.fixedRotation = true;
		bodyDef.position.set(tileX/screenScale, tileY/screenScale);
		var fixtureDef = new B2FixtureDef();

		var boxShape = new B2PolygonShape();
		boxShape.setAsBox(
			(GameObject.spriteWidth * 0.9 * 0.5)/screenScale, 
			(GameObject.spriteHeight * 0.92 * 0.5)/screenScale
		);

		fixtureDef.filter.categoryBits = 0x0002;
		fixtureDef.filter.maskBits = 0x0001 | 0x0002;
		fixtureDef.shape = boxShape;
		fixtureDef.friction = 1.0;
		fixtureDef.density = 1.0;

		bodyDef.type = B2Body.b2_dynamicBody;
		bodyDef.allowSleep = false;

		body = world.createBody(bodyDef);
		body.setUserData(this);

		body.createFixture(fixtureDef);

	}

	function isHoldingOnToLadder() {
		return ladderJoint != null;
	}

	function animate() {
		// Flip sprite if it starts going in a new direction. But when it stops it should remain
		// facing the direction it was previously going towards.
		if (Math.abs(body.getLinearVelocity().x) > 0.1) {
			this.flipped = body.getLinearVelocity().x < 0;
		}

		var falling = false;
		if (body.getLinearVelocity().y > 1) {
			falling = true;
		}

		if (falling || isHoldingOnToLadder()) {
			frame = 5;
		} else {

			if (frame == 5) {
				frame = 2;
			}

			frame += Math.abs(body.getLinearVelocity().x) * (0.025);
			if (frame > 4) {
				frame = 1;
			}
		}
	}

	override public function draw(buffer:BitmapData, sheet:BitmapData, bodyX:Int, bodyY:Int) {
		copyPixelsFromSpriteSheet(buffer, sheet, new Point(
			bodyX - 10, 
			bodyY - 11
		));
		animate();
	}

	function makeLadderJoint(ladder, grabOffset:Float) {
		var jointDef = new B2DistanceJointDef();

//		ladder.getPosition();
//		var pos:B2Vec2 = ladder.getPosition();
/*		pos.x -= body.getPosition().x;
		pos.y -= body.getPosition().y;
*/

		var bA : box2D.dynamics.B2Body = ladder;			
		var bB : box2D.dynamics.B2Body = body;			
		var anchorA : box2D.common.math.B2Vec2 = bA.getPosition();
		var anchorB : box2D.common.math.B2Vec2 = bB.getPosition();

		anchorA.add(new B2Vec2(0.0, 0.1));

		jointDef.initialize(bA, bB, anchorA, anchorB);
/*
		jointDef.bodyA = ladder; 
		jointDef.bodyB = body;

		// Oh it's like .. in the coordinate system so much that ig

		// Connect center of the guy with the point in ladder that he is over.
		jointDef.localAnchorA = new B2Vec2(
			body.getPosition().x - ladder.getPosition().x,
			body.getPosition().y - ladder.getPosition().y
		); // Will cause mayhem, but let's just try it
		jointDef.localAnchorB = new B2Vec2(0.0, grabOffset);

		jointDef.length = 0.0;
*/
		ladderJoint = world.createJoint(jointDef);			
	}

	function tryGrabbingLadder() {		
		var ladder = overLadder();
		if (ladder != null) {
			makeLadderJoint(ladder, 0.0);
		}
	}

	function moveAlongLadder(up:Bool) {		
		letGoOfLadder();
		var ladder = overLadder();
		makeLadderJoint(ladder, up ? climbSpeed : -climbSpeed);

/*		var amount = up ? climbSpeed : -climbSpeed;

		var ladderBody = ladderJoint.getBodyB();
		world.destroyJoint(ladderJoint);

		var jointDef = new B2DistanceJointDef();
		jointDef.bodyA = body; 
		jointDef.bodyB = ladderBody;
		jointDef.localAnchorA = new B2Vec2(0.0, 0.0);
		jointDef.localAnchorB = new B2Vec2(0.0, 0.0);
		return world.createJoint(jointDef);*/
	}

	// Big arrows can be shot up to actually remove tiles so the player can fall to the ground.trace
	// Could drop ... fuck it stop having ideas and start doing prototyping.

	function letGoOfLadder() {
		if (ladderJoint != null) {
			world.destroyJoint(ladderJoint);
			ladderJoint = null;
		}
	}

/*	function jump() {
		// Sample points on bottom left and bottom right to decide whether there is ground below.
		var groundBelow = someBodyAtPoint(player.getWorldCenter().x + GameObject.tileWidth * 0.4, player.getWorldCenter().y + GameObject.tileHeight * 0.55)
		|| someBodyAtPoint(player.getWorldCenter().x - GameObject.tileWidth * 0.4, player.getWorldCenter().y + GameObject.tileHeight * 0.55);

		if (groundBelow || isOnLadder()) {
			canStillJumpTicks = jumpTicks;
		}

		if (isOnLadder()) {
			letGoOfLadder();
		}

		// Can hover in the air a bit after jumping to control jumping height
		canStillJumpTicks--;
		if (canStillJumpTicks > 0) {
			player.applyImpulse(new B2Vec2(
				0.0,
				-jumpImpulse
			), player.getWorldCenter());
		}
	}*/
}
