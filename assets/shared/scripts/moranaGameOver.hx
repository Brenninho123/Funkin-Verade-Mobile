import substates.GameOverSubstate;

var moranaSnap:FlxAnimate;
var bf:Character;

function create() {
	Paths.cacheBitmap('images/characters/morganaWAKEUP/spritemap1.png');
	Paths.returnSound('sounds/WAKE_TF_UP', null, true, false);
	Paths.returnSound('sounds/wakeCall', null, true, false);
}

function onGameOverStart() {
	bf = GameOverSubstate.instance.boyfriend;

	moranaSnap = new FlxAnimate(bf.x - 350, bf.y + 20);
	Paths.loadAnimateAtlas(moranaSnap, 'characters/morganaWAKEUP');
	moranaSnap.anim.addBySymbol('snap', 'Símbolo 1', 24, false);
	moranaSnap.visible = false;
	moranaSnap.angle = 45;
	GameOverSubstate.instance.insert(0, moranaSnap);
}

function onGameOverConfirm(isAccept)
{
	if (!isAccept) return;
	GameOverSubstate.instance.isEnding = true;
	FlxG.sound.music.fadeOut(0.35);
	FlxG.sound.play(Paths.sound('WAKE_TF_UP'));
	final soundTime:Float = 2.2;

	// Código do retry de vdd, timer pra alinhar com o "ACORDA!"
	FlxTimer.wait(soundTime + 0.28, () -> 
	{
		if (bf.hasAnimation('deathConfirm')) bf.playAnim('deathConfirm', true);

		FlxG.sound.play(Paths.music(GameOverSubstate.endSoundName), 0.22);
		FlxG.camera.fade(FlxColor.BLACK, 3.5, false, FlxG.resetState);
	});

	// O som de estalo kk
	FlxTimer.wait(soundTime + 0.12, () -> FlxG.sound.play(Paths.sound('wakeCall'), 0.2));

	// A morana indo acordar (reviver) o blulfi
	FlxTimer.wait(soundTime, () -> 
	{
		moranaSnap.visible = true;
		moranaSnap.anim.play('snap');
	});
	return Function_Stop;
}