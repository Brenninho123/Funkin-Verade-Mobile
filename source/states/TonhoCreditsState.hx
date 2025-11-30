package states;

import objects.AttachedSprite;
import flixel.group.FlxContainer.FlxTypedContainer;

private typedef CredEntry = 
{
	name:String,
	frameChar:String,

	role:String,
	doings:String, // Lista doq fez

	?socials:Array<SocialHandle>,
}

private typedef SocialHandle = 
{
	display:String,
	link:String,
	social:String
}

enum abstract SocialMediaType(String) from String to String
{
	public static final TWITTER:String = "Xwitter";
	public static final DISCORD:String = "Discord";
	public static final YT:String = "YouTube";
	public static final NG:String = "Newgrounds";
	public static final OTHER:String = "???";
}

private class SocialMedia
{
	private var _data:SocialHandle;
	public var social(default, null):SocialMediaType = SocialMediaType.OTHER;

	public function new(data:SocialHandle)
	{
		_data = data;
		social = socialFromString(_data.social);
	}

	public static inline function socialFromString(string:String):SocialMediaType
	{
		return switch (string.toLowerCase())
		{
			case "twitter": SocialMediaType.TWITTER;
			case "dc": SocialMediaType.DISCORD;
			case "yt": SocialMediaType.YT;
			case "ng": SocialMediaType.NG;
			default: SocialMediaType.OTHER;
		};
	}

	public inline function getWebsite():String
	{
		return switch (social)
		{
			case SocialMediaType.TWITTER: 'x.com/${_data.link}';
			case SocialMediaType.DISCORD: 'discord.com/users/${_data.link}';
			case SocialMediaType.YT: 'youtube.com/@${_data.link}';
			case SocialMediaType.NG: '${_data.link}.newgrounds.com';
			default: _data.link;
		};
	}

	public inline function getAccName():String { return _data.display ?? '@${_data.link}'; }
	public inline function toString():String { return social; }
}

class TonhoCreditsState extends MusicBeatState
{
	var creds:Array<CredEntry> = [];
	var colors:Map<String, Array<FlxColor>> = 
	[ // As setas já possuem as cores dos principais
		"torajo" => [ClientPrefs.defaultData.arrowRGB[2][0], ClientPrefs.defaultData.arrowRGB[2][2]],
		"morajo" => [ClientPrefs.defaultData.arrowRGB[1][0], ClientPrefs.defaultData.arrowRGB[1][2]],
		"linn" => [ClientPrefs.defaultData.arrowRGB[0][0], ClientPrefs.defaultData.arrowRGB[0][2]],
		"zulmi" => [ClientPrefs.defaultData.arrowRGB[3][0], ClientPrefs.defaultData.arrowRGB[3][2]],
		"azedo" => [0xFF277017, 0xFF874DF7],
		"pessy" => [0xFFFE992F, 0xFF2C1B9F],
		"default" => [0xFFADADAD, 0xFF3F3F3F]
	];
	var socialDatas:Array<Array<SocialMedia>> = [];

	var blockInput:Bool;
	static var curSelected:Int;
	static var alreadyIntrodid:Bool;

	var portraitGroup:FlxTypedContainer<FlxSprite>;
	var camFollow:flixel.FlxObject;
	var gradColor:shaders.RGBPalette;
	var infoBG:FlxSprite;

	var descTxt:FlxText;
	var social1Ico:AttachedSprite;
	var social1:FlxText;
	var social2Ico:AttachedSprite;
	var social2:FlxText;

	public function new()
	{
		creds = haxe.Json.parse(Paths.getTextFromFile('data/menus/credits.json')).d;
		curSelected = FlxMath.wrap(curSelected, 0, creds.length - 1);

		super();
	}

	inline function playMenuSong()
	{
		Paths.avoidDumping(Paths.getSharedPath('music/creditsMenu.${Paths.SOUND_EXT}')); // Incase you come back here

		FlxG.sound.playMusic(Paths.music('creditsMenu'), alreadyIntrodid ? 0.7 : 0);
		if (!alreadyIntrodid) FlxG.sound.music.fadeIn(4, 0, 0.7);
		Conductor.bpm = 110;
		alreadyIntrodid = true;
	}

	override function create()
	{
		FlxG.mouse.visible = true;
		#if DISCORD_ALLOWED DiscordClient.changePresence("Looking at the team", "Credits Menu"); #end
		playMenuSong();
		super.create();

		var socials:Array<SocialMediaType> = [SocialMediaType.DISCORD, SocialMediaType.YT, SocialMediaType.TWITTER, SocialMediaType.NG];
		for (s in socials) Paths.cacheBitmap('images/credits/socials/$s.png');
		Paths.cacheBitmap('images/achievements/menu/unknownAchieve.png');
		socials.resize(0);

		camFollow = new flixel.FlxObject(0, 0, 1, 1);
		camera.follow(camFollow, LOCKON, 0.6);

		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image('veradeBG'));
		bg.setGraphicSize(FlxG.width, FlxG.height); bg.updateHitbox();
		bg.screenCenter();
		bg.active = false;
		bg.scrollFactor.set();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		if (!ClientPrefs.data.lowQuality)
		{
			gradColor = new shaders.RGBPalette();

			var bgGrad:FlxSprite = new FlxSprite(0, 0, flixel.util.FlxGradient.createGradientBitmapData(1, 255, [FlxColor.RED, FlxColor.BLUE]));
			bgGrad.setGraphicSize(FlxG.width, FlxG.height); bgGrad.updateHitbox();
			bgGrad.screenCenter();
			bgGrad.shader = gradColor.shader;
			bgGrad.blend = MULTIPLY;
			bgGrad.active = false;
			bgGrad.scrollFactor.set();
			add(bgGrad);

			var bgGrid:flixel.addons.display.FlxBackdrop = new flixel.addons.display.FlxBackdrop(flixel.addons.display.FlxGridOverlay.createGrid(20, 20, 40, 40, true, FlxColor.WHITE, FlxColor.TRANSPARENT));
			bgGrid.scale.set(2.5, 2.5); bgGrid.updateHitbox();
			bgGrid.velocity.set(15, 15);
			bgGrid.alpha = 0.13;
			bgGrid.scrollFactor.set();
			add(bgGrid);
		}

		portraitGroup = new FlxTypedContainer<FlxSprite>();
		add(portraitGroup);

		for (i=>e in creds)
		{
			var imgPath:String = 'credits/portraits/${e.name}';
			if (!Paths.fileExists('images/$imgPath.png', IMAGE)) imgPath = 'credits/portraits/TBA';
			e.doings ??= "...Não sei quem é não";

			var portrait:FlxSprite = new FlxSprite(0, 0, Paths.image(imgPath));
			portrait.setGraphicSize(670); portrait.updateHitbox();
			portrait.y = (portrait.height + 8) * i;
			portrait.active = false;
			portrait.antialiasing = ClientPrefs.data.antialiasing;
			portraitGroup.add(portrait);

			if (e.socials == null)
			{
				socialDatas.push(null);
				continue;
			}
			socialDatas.push([for (d in e.socials) new SocialMedia(d)]);
		}

		infoBG = new FlxSprite(0, 50).makeGraphic(1, 1, FlxColor.BLACK);
		infoBG.setGraphicSize(500, 600); infoBG.updateHitbox();
		infoBG.screenCenter(X).x += portraitGroup.members[0].width / 2;
		infoBG.alpha = 0.4;
		infoBG.active = false;
		infoBG.scrollFactor.set();
		add(infoBG);

		descTxt = new FlxText(infoBG.x + 12, infoBG.y + 12, infoBG.width - 24);
		descTxt.setFormat(Paths.font("fraiche.ttf"), 32, FlxColor.PURPLE, LEFT);
		descTxt.setBorderStyle(OUTLINE_FAST, 0xFF46053C, 2);
		descTxt.antialiasing = true;
		descTxt.scrollFactor.set();
		add(descTxt);

		var separator:FlxSprite = new FlxSprite().makeGraphic(1, 1);
		separator.setGraphicSize(12, (150 / 2) + 32); separator.updateHitbox();
		separator.setPosition(infoBG.x + ((infoBG.width / 2) - (separator.width / 2)), (infoBG.y + infoBG.height) - (separator.height + 12));
		separator.alpha = infoBG.alpha / 2;
		separator.scrollFactor.set();
		add(separator);

		social1 = new FlxText(infoBG.x + 12, (infoBG.y + infoBG.height) - 32, (infoBG.width / 2) - (separator.width * 2.5));
		social1.setFormat(Paths.font("tardling.ttf"), 24, 0xFFEA2D1F, CENTER);
		social1.setBorderStyle(OUTLINE, 0xFFE9724C, 1.35);
		social1.antialiasing = true;
		social1.scrollFactor.set();

		social1Ico = new AttachedSprite('credits/socials/Discord'); // Just to have image size for position calc
		social1Ico.scale.set(0.5, 0.5); social1Ico.updateHitbox();
		social1Ico.sprTracker = social1;
		social1Ico.xAdd = social1Ico.width;
		social1Ico.yAdd = -social1Ico.height;
		social1Ico.copyVisible = true;
		social1Ico.antialiasing = false;

		social2 = new FlxText((separator.x + separator.width) + 12, social1.y, social1.fieldWidth);
		social2.setFormat(social1.font, social1.size, 0xFFEA2D1F, CENTER);
		social2.setBorderStyle(social1.borderStyle, social1.borderColor, social1.borderSize);
		social2.antialiasing = social1.antialiasing;
		social2.scrollFactor.set();

		social2Ico = new AttachedSprite('credits/socials/Discord');
		social2Ico.scale.copyFrom(social1Ico.scale); social2Ico.updateHitbox();
		social2Ico.sprTracker = social2;
		social2Ico.xAdd = social2Ico.width;
		social2Ico.yAdd = -social2Ico.height;
		social2Ico.copyVisible = true;
		social2Ico.antialiasing = social1Ico.antialiasing;

		add(social1Ico);
		add(social2Ico);
		add(social1);
		add(social2);

		camFollow.x = FlxG.width - portraitGroup.members[0].width;
		changeSelection(0);
		camera.snapToTarget();
	}

	override function update(elapsed:Float)
	{
		if (blockInput)
		{
			super.update(elapsed);
			return;
		}

		if (controls.UI_UP_P || controls.UI_DOWN_P) changeSelection(controls.UI_UP_P ? -1 : 1);

		if (controls.BACK)
		{
			blockInput = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));

			FlxG.switchState(() -> new MainMenuState());
		}

		if (social1 != null && social1.visible)
		{
			social1.underline = FlxG.mouse.overlaps(social1);
			social1.color = social1.underline ? 0xFFFFC857 : 0xFFEA2D1F;
			if (social1.underline && FlxG.mouse.justPressed) CoolUtil.browserLoad(socialDatas[curSelected][0].getWebsite());
		}
		if (social2 != null && social2.visible)
		{
			social2.underline = FlxG.mouse.overlaps(social2);
			social2.color = social2.underline ? 0xFFFFC857 : 0xFFEA2D1F;
			if (social2.underline && FlxG.mouse.justPressed) CoolUtil.browserLoad(socialDatas[curSelected][1].getWebsite());
		}

		super.update(elapsed);
	}

	function changeSelection(change:Int)
	{
		if (socialDatas[curSelected] != null)
		{
			if (socialDatas[curSelected][0].social == SocialMediaType.OTHER)
			{
				social1Ico.scale.set(0.5, 0.5);
				social1Ico.updateHitbox();
			}

			if (socialDatas[curSelected][1]?.social == SocialMediaType.OTHER)
			{
				social2Ico.scale.set(0.5, 0.5);
				social2Ico.updateHitbox();
			}
		}

		curSelected = FlxMath.wrap(curSelected + change, 0, creds.length - 1);
		changeGradient(colors[creds[curSelected].frameChar] ?? colors["default"]);

		camFollow.y = portraitGroup.members[curSelected].y + (portraitGroup.members[curSelected].height / 2);
		descTxt.text = '[${creds[curSelected].role}]\n${creds[curSelected].doings}';

		social1.visible = social2.visible = socialDatas[curSelected] != null;
		if (!social1.visible) return;
		updateSocialInfo(socialDatas[curSelected][0], social1, social1Ico);

		social2.visible = socialDatas[curSelected].length >= 2;
		if (!social2.visible) return;
		updateSocialInfo(socialDatas[curSelected][1], social2, social2Ico);
	}

	override function destroy()
	{
		colors.clear();
		creds.resize(0);
		socialDatas.resize(0);
		super.destroy();
	}

	inline function changeGradient(colors:Array<FlxColor>)
	{
		if (gradColor == null) return;

		gradColor.r = colors[0];	
		gradColor.b = colors[1];
	}

	inline function updateSocialInfo(socialData:SocialMedia, text:FlxText, icon:FlxSprite)
	{
		text.text = socialData.getAccName();
		text.y = (infoBG.y + infoBG.height) - (text.height + 12);

		final unknownSocial:Bool = socialData.social == SocialMediaType.OTHER;
		icon.loadGraphic(!unknownSocial ? Paths.image('credits/socials/${socialData.social}') : Paths.image('achievements/menu/unknownAchieve'));
		if (unknownSocial) icon.setGraphicSize(150 / 2);
		icon.updateHitbox();
	}
}