package states;

import shaders.RGBPalette;
import flixel.group.FlxSpriteContainer;
import haxe.Json;
import flixel.util.FlxGradient;

private typedef CredEntry = 
{
	name:String,
	desc:String,

	// expression:String,
	frameChar:Null<String>
}

class CoolCreditsState extends FlxTransitionableState
{
	static var creds:Array<CredEntry>;
	final colors:Map<String, Array<FlxColor>> = 
	[
		"torajo" => [0xFF4BF57B, 0xFFBD5AE8],
		"morajo" => [0xFFFF6968, 0xFF5CF7F3],
		"linn" => [0xFFFFF1AA, 0xFFED1F12],
		"zulmi" => [0xFF5A68E2, 0xFFFBDA71],
		"default" => [0xFFADADAD, 0xFF3F3F3F]
	];

	var blockInput:Bool;
	static var curSelected:Int;

	var portraitGroup:FlxSpriteContainer = new FlxSpriteContainer();
	var gradColor:RGBPalette = new RGBPalette();

	override function create()
	{
		creds = Json.parse(Paths.getTextFromFile('data/menus/credits.json')).d;
		super.create();

		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image('veradeBG'));
		bg.screenCenter();
		bg.active = false;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		var bgGrad:FlxSprite = new FlxSprite(0, 0, FlxGradient.createGradientBitmapData(200, 120, [FlxColor.RED, FlxColor.BLUE]));
		bgGrad.setGraphicSize(FlxG.width, FlxG.height); bgGrad.updateHitbox();
		bgGrad.screenCenter();
		bgGrad.shader = gradColor.shader;
		bgGrad.blend = MULTIPLY;
		bgGrad.active = false;
		add(bgGrad);

		var bgGrid:flixel.addons.display.FlxBackdrop = new flixel.addons.display.FlxBackdrop(flixel.addons.display.FlxGridOverlay.createGrid(50, 50, 100, 100, true, 0xFFFFFFFF, FlxColor.TRANSPARENT));
		bgGrid.velocity.set(15, 15);
		bgGrid.alpha = 0.1;
		add(bgGrid);

		add(portraitGroup);
		for (e in creds)
		{
			var imgPath:String = 'credits/portraits/${e.name}';
			if (!Paths.fileExists('images/$imgPath.png', IMAGE)) imgPath = 'credits/portraits/TBA';

			var portrait:FlxSprite = new FlxSprite(0, 0, Paths.image(imgPath));
			portrait.scale.scale(0.5, 0.5); portrait.updateHitbox();
			// portrait.x += (portrait.width + 120);
			portrait.active = false;
			portrait.antialiasing = ClientPrefs.data.antialiasing;
			portraitGroup.add(portrait);
		}
		portraitGroup.screenCenter();

		changeSelection(0);
	}

	override function update(elapsed:Float)
	{
		if (blockInput)
		{
			super.update(elapsed);
			return;
		}

		if (Controls.instance.UI_LEFT_P || Controls.instance.UI_RIGHT_P) changeSelection(Controls.instance.UI_LEFT_P ? -1 : 1);

		if (Controls.instance.BACK)
		{
			blockInput = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(() -> new MainMenuState());
		}

		super.update(elapsed);
	}

	function changeSelection(change:Int)
	{
		portraitGroup.members[curSelected].visible = false;

		curSelected = FlxMath.wrap(curSelected + change, 0, creds.length - 1);
		changeGradient(colors[creds[curSelected].frameChar] ?? colors["default"]);

		portraitGroup.members[curSelected].visible = true;
	}

	inline function changeGradient(colors:Array<FlxColor>)
	{
		gradColor.r = colors[0];	
		gradColor.b = colors[1];
	}
}