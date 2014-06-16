import flash.geom.*;
import flash.display.*;
import box2D.dynamics.*;
import box2D.dynamics.joints.*;
import box2D.common.math.*;

class StickMan extends GameObject {

	// If holding on to a ladder, this joint connects him to it.
	var ladderJoint:B2Joint = null;
	var climbSpeed = 0.05;
	var jumpTicks = 5;
	var canStillJumpTicks = 5; // countdown for how long can still continue jumping

	override public function new(body:B2Body, world:B2World, screenScale:Float) {
		super(body, world, screenScale);
		frame = 1;
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

	function tryGrabbingLadder() {
		var ladder = overLadder();
		if (ladder != null) {
			var jointDef = new B2DistanceJointDef();
			jointDef.bodyA = body; 
			jointDef.bodyB = ladder;
			jointDef.localAnchorA = new B2Vec2(0.0, 0.0); // Will cause mayhem, but let's just try it
			jointDef.localAnchorB = new B2Vec2(0.0, 0.0);
			ladderJoint = world.createJoint(jointDef);			
		}
	}

	function moveAlongLadder(up:Bool) {

		var amount = up ? climbSpeed : -climbSpeed;

		var ladderBody = ladderJoint.getBodyB();
		world.destroyJoint(ladderJoint);

		var jointDef = new B2DistanceJointDef();
		jointDef.bodyA = body; 
		jointDef.bodyB = ladderBody;
		jointDef.localAnchorA = new B2Vec2(0.0, 0.0);
		jointDef.localAnchorB = new B2Vec2(0.0, 0.0);
		return world.createJoint(jointDef);

	}

	// Big arrows can be shot up to actually remove tiles so the player can fall to the ground.trace
	// Could drop ... fuck it stop having ideas and start doing prototyping.

	function letGoOfLadder() {
		world.destroyJoint(ladderJoint);
		ladderJoint = null;
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
