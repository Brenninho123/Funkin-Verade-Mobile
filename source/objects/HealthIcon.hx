package objects;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isPlayer:Bool = false;
	public var char(default, null):String = '';
	public var autoAdjustOffset:Bool = true;

	public function new(char:String = 'face', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char, allowGPU);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (sprTracker == null) return;

		setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String, ?allowGPU:Bool = true)
	{
		if (char == this.char || char == this.char.replace("-pixel", "")) return;
		final lastAnimFrame:Int = animation.curAnim?.curFrame;

		var name:String = 'icons/$char';
		if (
			!Paths.fileExists('images/$name.png', IMAGE) 
			&& !Paths.fileExists('images/${name += '-pixel'}.png', IMAGE)
		)
			name = 'icons/face';
		
		var graphic = Paths.image(name, allowGPU);
		var grid:Float = Math.round(graphic.width / graphic.height);
		loadGraphic(graphic, true, Math.floor(graphic.width / grid));
		iconOffsets[0] = (width - 150) / grid;
		iconOffsets[1] = (height - 150) / grid;
		updateHitbox();

		animation.add(char, [for (i in 0...frames.frames.length) i], 0, false, isPlayer);
		animation.play(char, true, false, lastAnimFrame);
		this.char = name.substr(6);

		if (!ClientPrefs.data.antialiasing) return;
		antialiasing = !this.char.endsWith("-pixel");
	}

	override function updateHitbox()
	{
		if (!autoAdjustOffset)
		{
			super.updateHitbox();
			return;
		}

		super.updateHitbox();
		offset.set(iconOffsets[0], iconOffsets[1]);
	}
}
