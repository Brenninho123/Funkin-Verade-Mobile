package states;

import flixel.util.FlxGradient;
import backend.WeekData;

import flixel.input.keyboard.FlxKey;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;

import openfl.Assets;
import openfl.display.BitmapData;
import states.StoryMenuState;
import states.MainMenuState;

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	var blockInput:Bool = false;
	public static var skippedIntro:Bool = false;

	var logo:FlxSprite;
	var titleText:FlxSprite;
	var chars:Array<FlxSprite> = []; // I REFUSE to create another group, they're too much of a hassle!
	final bopInterval:Int = 2;

	var credCam:FlxCamera;
	var credGroup:FlxGroup = new FlxGroup();
	var textGroup:FlxGroup = new FlxGroup();
	var curWacky:Array<String> = [];

	override function create()
	{
		FlxG.mouse.visible = false;
		super.create();

		initSprites();
		if (skippedIntro)
		{
			reloadMusic();
			return;
		}

		curWacky = FlxG.random.getObject(getIntroTextShit());
		initIntro();
	}

	inline function reloadMusic(fade:Bool = false)
	{
		if (FlxG.sound.music?.playing)
		{
			Conductor.bpm = 102;
			return;
		}

		FlxG.sound.playMusic(Paths.music('freakyMenu'), fade ? 0 : 1);
		if (fade) FlxG.sound.music.fadeIn(4, 0, 0.7);
		Conductor.bpm = 102;
	}

	function initSprites()
	{
		final bmp:BitmapData = Paths.image('veradeBG', false).bitmap; // Separate var just to avoid applying the filter on this
		var bmpClone:BitmapData = bmp.clone();
		bmpClone.applyFilter(bmpClone, bmp.rect, new openfl.geom.Point(), new openfl.filters.BlurFilter(1.5, 1.5, 2));
		bmpClone = FlxGradient.overlayGradientOnBitmapData(bmpClone, bmp.width, bmp.height, [0xA84BF57B, 0xA8BD5AE8]);

		var bg:FlxSprite = new FlxSprite(0, 0, bmpClone);
		bg.screenCenter();
		bg.active = false;
		bg.antialiasing = false;
		add(bg);

		var blueyBop:FlxSprite = new FlxSprite(365, 405);
		blueyBop.frames = Paths.getSparrowAtlas('titlescreen/chars/blfi');
		blueyBop.animation.addByIndices('danceLeft', 'blfi', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		blueyBop.animation.addByIndices('danceRight', 'blfi', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		blueyBop.scale.set(0.5, 0.5); blueyBop.updateHitbox();
		chars.push(blueyBop);

		var mornaaBop:FlxSprite = new FlxSprite((blueyBop.x + blueyBop.width) - 65, blueyBop.y - 25);
		mornaaBop.frames = Paths.getSparrowAtlas('titlescreen/chars/mona');
		mornaaBop.animation.addByPrefix('idle', 'mona', 24, false);
		mornaaBop.scale.set(0.53, 0.53); mornaaBop.updateHitbox();
		chars.push(mornaaBop);
		
		var tonhoBop:FlxSprite = new FlxSprite(0, 100);
		tonhoBop.frames = Paths.getSparrowAtlas('titlescreen/chars/tojo');
		tonhoBop.animation.addByIndices('danceLeft', 'tojo', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		tonhoBop.animation.addByIndices('danceRight', 'tojo', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		tonhoBop.scale.set(0.5, 0.5); tonhoBop.updateHitbox();
		chars.push(tonhoBop);

		var morjoBop:FlxSprite = new FlxSprite(FlxG.width, tonhoBop.y);
		morjoBop.frames = Paths.getSparrowAtlas('titlescreen/chars/mojo');
		morjoBop.animation.addByPrefix('idle', 'mojo', 24, false);
		morjoBop.scale.set(0.5, 0.5); morjoBop.updateHitbox();
		morjoBop.x -= morjoBop.width + (40 - tonhoBop.x);
		chars.push(morjoBop);

		logo = new FlxSprite(0, 0, Paths.image('titlescreen/logo'));
		logo.scale.set(0.3, 0.3); logo.updateHitbox();
		logo.screenCenter().y -= 155;
		logo.active = false;
		logo.antialiasing = ClientPrefs.data.antialiasing;

		for (s in chars) add(s);
		add(logo);

		titleText = new FlxSprite();
		titleText.frames = Paths.getSparrowAtlas('titlescreen/titleEnter');
		titleText.animation.addByPrefix('idle', "ENTER IDLE", 0, false);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.animation.play('idle');
		titleText.screenCenter(X).y = (FlxG.height - titleText.height) - 25;
		titleText.color = FlxColor.BLACK;
		titleText.antialiasing = true;
		add(titleText);
	}

	inline function initIntro()
	{
		credCam = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		FlxG.cameras.add(credCam, false);
		
		credGroup.camera = credCam;
		credGroup.visible = false;
		add(credGroup);

		textGroup.camera = credCam;
		add(textGroup);

		var we:FlxSprite = createCoolSprite(0, 132, 'nois');
		we.scale.set(0.4, 0.4); we.updateHitbox();
		we.screenCenter(X);

		reloadMusic(true);
	}
	
	function getIntroTextShit():Array<Array<String>>
	{
		var list:Array<String> = CoolUtil.coolTextFile(Paths.txt('menus/introText'));

		var lines:Array<Array<String>> = [for (t in list) t.split("--")];
		return lines;
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music?.playing) Conductor.songPosition = FlxG.sound.music.time;

		if (skippedIntro)
		{
			logo.scale.set(
				FlxMath.lerp(0.3, logo.scale.x, Math.exp(-elapsed * 2)),
				FlxMath.lerp(0.3, logo.scale.y, Math.exp(-elapsed * 2))
			); logo.updateHitbox();
			logo.y = (logo.screenCenter().y - 155);
		}

		if (blockInput)
		{
			super.update(elapsed);
			return;
		}

		if (FlxG.keys.justPressed.ENTER 
		#if FLX_TOUCH || FlxG.touches.getFirst()?.justPressed #end
		|| (FlxG.gamepads.lastActive?.justPressed.START || FlxG.gamepads.lastActive?.justPressed.A))
			enterPress();

		super.update(elapsed);
	}

	function createCoolSprite(x:Float, y:Float, image:String, ?sheetUser:Bool = false):FlxSprite
	{
		if (!image.startsWith("titlescreen/")) image = 'titlescreen/$image';

		var spr:FlxSprite = new FlxSprite(x, y);
		switch (sheetUser)
		{
			case false: spr.loadGraphic(Paths.image(image));
			case true:
				spr.frames = Paths.getAtlas(image);
				spr.animation.addByPrefix('anim', image, 24, false);
		}
		spr.antialiasing = ClientPrefs.data.antialiasing;

		credGroup.add(spr);
		return spr;
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		if (textArray.length == 1)
		{
			addMoreText(textArray[0], offset);
			return;
		}

		for (i=>t in textArray) __makeText(i, offset, t);
	}

	inline function addMoreText(text:String, ?offset:Float = 0)
	{
		__makeText(textGroup.length, offset, text);
	}

	function deleteCoolText(?deleteImagesOnly:Bool = false)
	{
		if (!deleteImagesOnly)
		{
			for (t in textGroup) t.destroy();
			textGroup.clear();
		}

		if (!credGroup.visible) return;

		for (s in credGroup) s.destroy();
		credGroup.clear();
		credGroup.visible = false;
	}

	function skipIntro()
	{
		if (skippedIntro) return;
		skippedIntro = true;

		FlxG.cameras.remove(credCam);
		deleteCoolText();
		for (g in [credGroup, textGroup])
		{
			g.destroy();
			remove(g, true);
		}

		FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 4);
	}

	function charBop(beat:Int)
	{
		if (chars.length == 0) return;
		for (c in chars)
		{
			final danceIdle:Bool = !c.animation.exists("idle");
			final interval:Int = !danceIdle ? bopInterval : Math.round(bopInterval / 2);
			if (beat % interval != 0) continue;

			final anim:String = !danceIdle ? "idle" : (c.animation.name.endsWith("Left") ? "danceRight" : "danceLeft");
			c.animation.play(anim, true);
		}
	}

	override function beatHit()
	{
		super.beatHit();
		if (skippedIntro)
		{
			final add:Float = (curBeat % 2 == 0) ? -0.05 : 0.05;
			logo.scale.add(add, add);
			charBop(curBeat);
			return;
		}

		var hasWackyImage:Bool = curWacky[0].startsWith(":png:") || curWacky[1].startsWith(":png:");
		var secondWacky:Bool = hasWackyImage && !curWacky[0].startsWith(":png:");

		switch (curBeat)
		{
			case 1: credGroup.visible = true;
			case 3: addMoreText('apresenta', 270);
			case 4:
				deleteCoolText();

				var tonho:FlxSprite = createCoolSprite(0, 0, 'Torajinho');
				tonho.scale.set(0.35, 0.35); tonho.updateHitbox();
				tonho.screenCenter();
			case 5: createCoolText(['O Torajo'], -45);
			case 7:
				credGroup.visible = true;
				addMoreText('faz uma live ae', 235);

			case 8:
				deleteCoolText();

				var ng:FlxSprite = createCoolSprite(0, 0, 'newgrounds_logo');
				ng.scale.set(0.35, 0.35); ng.updateHitbox();
				ng.screenCenter().y += 75;
			case 9: createCoolText(['Não tamo na'], -20);
			case 10: credGroup.visible = true;

			case 11:
				deleteCoolText();

				if (hasWackyImage)
				{
					final imgStr:String = curWacky[secondWacky ? 1 : 0].substr(5);
					var wackyImage:FlxSprite = createCoolSprite(0, 0, imgStr, Paths.fileExists('images/$imgStr.xml', TEXT));
					wackyImage.scale.set(0.35, 0.35); wackyImage.updateHitbox();
					wackyImage.screenCenter();
					if (!secondWacky) wackyImage.y -= 90;
					else wackyImage.y = (FlxG.height - wackyImage.height) - 60;
				}

				var theWacky:String = !secondWacky ? curWacky[hasWackyImage ? 1 : 0] : curWacky[0];
				createCoolText([theWacky]);
				credGroup.visible = !secondWacky;
			case 12:
				if (!secondWacky) deleteCoolText(true);

				var theWacky:String = secondWacky ? curWacky[2] ?? "...isso aí, eu acho.." : curWacky[1];
				addMoreText(theWacky);
				credGroup.visible = secondWacky;
			case 13:
				deleteCoolText();

				addMoreText('Funkin\'');
			case 14: addMoreText('em');
			case 15: addMoreText('Verade');
			case 16: skipIntro();
		}
	}

	function enterPress()
	{
		if (!skippedIntro)
		{
			skipIntro();
			return;
		}

		blockInput = true;
		titleText.animation.play('press');
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

		FlxTimer.wait(1, () -> 
			FlxG.switchState(() -> new MainMenuState()));
	}

	@:noCompletion
	function __makeText(pos:Int, offset:Float, text:String)
	{
		var textSpr:Alphabet = new Alphabet(0, (60 * pos) + (200 + offset), text);
		textSpr.screenCenter(X);
		textGroup.add(textSpr);

		final diff:Float = Math.max((textSpr.width - FlxG.width) / FlxG.width, 1);
		final scaleToAppear:Float = 1 - diff;
		textSpr.scaleX = scaleToAppear > 0 ? scaleToAppear : 1;
	}
}