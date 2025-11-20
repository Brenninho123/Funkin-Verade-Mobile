package objects;

import flixel.group.FlxSpriteContainer;
import shaders.RGBPalette;

class HealthIcon extends FlxSpriteContainer
{
	public var sprTracker:FlxSprite;
	private var isPlayer:Bool = false;

	public var char(default, null):String = "";
	public var charSprite:FlxSprite = new FlxSprite();

	public var fruit(default, null):String = "";
	public var fruitSprite:FlxSprite = new FlxSprite(-15, -7);
	public var fruitRGB:RGBPalette = new RGBPalette();

	public function new(char:String = 'face', isPlayer:Bool = false, ?fruit:String, ?allowGPU:Bool = true)
	{
		super();
		this.isPlayer = isPlayer;
		scrollFactor.set();

		if (fruit != null)
		{
			changeFruit(fruit, allowGPU);
			add(fruitSprite);
		}
		changeIcon(char, allowGPU);
		add(charSprite);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (sprTracker == null) return;

		setPosition((sprTracker.x + sprTracker.width) + 12, sprTracker.y - 30);
	}

	public function changeIcon(char:String, ?allowGPU:Bool = true)
	{
		if (char == this.char || char == this.char.replace("-pixel", "")) return;
		final lastAnimFrame:Int = charSprite.animation.curAnim?.curFrame;

		var name:String = 'icons/$char';
		if (
			!Paths.fileExists('images/$name.png', IMAGE) 
			&& !Paths.fileExists('images/${name += '-pixel'}.png', IMAGE)
		)
			name = 'icons/face';
		
		final graphic:flixel.graphics.FlxGraphic = Paths.image(name, allowGPU);
		final grid:Float = Math.round(graphic.width / graphic.height);
		charSprite.loadGraphic(graphic, true, Math.floor(graphic.width / grid));

		charSprite.animation.add(char, [for (i in 0...charSprite.frames.frames.length) i], 0, false, isPlayer);
		charSprite.animation.play(char, true, false, lastAnimFrame);
		this.char = name.substring(name.lastIndexOf("/") + 1);

		if (!ClientPrefs.data.antialiasing) return;
		charSprite.antialiasing = !this.char.endsWith("-pixel");
	}

	public function changeFruit(fruit:String, ?allowGPU:Bool = true)
	{
		if (fruit == this.fruit || fruit == this.fruit.replace("-pixel", "")) return;
		fruitSprite.shader = null;

		var name:String = 'icons/fruit-$fruit';
		if (
			!Paths.fileExists('images/$name.png', IMAGE) 
			&& !Paths.fileExists('images/${name += '-pixel'}.png', IMAGE)
		)
			name = 'icons/fruit-jabuticaba';

		fruitSprite.loadGraphic(Paths.image(name));
		fruitSprite.shader = fruitRGB.shader;

		fruitSprite.flipX = isPlayer;
		this.fruit = name.substring(name.lastIndexOf("-") + 1);

		if (!ClientPrefs.data.antialiasing) return;
		fruitSprite.antialiasing = !this.fruit.endsWith("-pixel");
	}
}
