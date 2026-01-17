package objects;

class GamepadCursor extends flixel.addons.display.shapes.FlxShapeCircle
{
	public var useBothSticks:Bool = true;
	public var speed:Float;

	public function new(speed:Float = 4, scale:Float = 1, color:FlxColor = FlxColor.WHITE, outline:FlxColor = FlxColor.GRAY)
	{
		super(0, 0, 15 + (10 * (scale - 1)), {color: outline, thickness: 7.5}, color);
		alpha = 0.5;
		this.speed = speed;
		visible = false; // Start invisible (so mouse doesn't get messed up), user controls the visibility

		screenCenter();
		antialiasing = ClientPrefs.data.antialiasing;
		scrollFactor.set();
	}	

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!visible) return;

		for (gamepad in FlxG.gamepads.getActiveGamepads())
		{
			final usedLeftStick:Bool = gamepad.analog.value.LEFT_STICK_X != 0 || gamepad.analog.value.LEFT_STICK_Y != 0;
			final usedRightStick:Bool = gamepad.analog.value.RIGHT_STICK_X != 0 || gamepad.analog.value.RIGHT_STICK_Y != 0;
			if (!usedLeftStick && !usedRightStick) continue;

			var stick:FlxPoint = FlxPoint.get(
				(usedLeftStick || !useBothSticks) ? gamepad.analog.value.LEFT_STICK_X : gamepad.analog.value.RIGHT_STICK_X,
				(usedLeftStick || !useBothSticks) ? gamepad.analog.value.LEFT_STICK_Y : gamepad.analog.value.RIGHT_STICK_Y
			);
			x = FlxMath.bound(x + (stick.x * speed), 0, FlxG.width - width);
			y = FlxMath.bound(y + (stick.y * speed), 0, FlxG.height - height);
			stick.put();
		}
	}
}