package backend;

/**
 * `PsychCamera` handles followLerp based on elapsed
 * and stops camera from snapping at higher framerates
 */
class PsychCamera extends FlxCamera
{
	override function updateLerp(elapsed:Float)
	{
		final mult:Float = 1 - Math.exp(-elapsed * followLerp / (1 / 60));
		scroll.x += (_scrollTarget.x - scroll.x) * mult;
		scroll.y += (_scrollTarget.y - scroll.y) * mult;
	}
}