package mobile.backend;

import flixel.FlxG;
import flixel.util.FlxSignal;
#if android
import android.content.Context;
#end
#if !macro
import lime.system.System;
#end

enum abstract BatteryStatus(Int) from Int to Int
{
	var UNKNOWN = 0;
	var CHARGING = 1;
	var DISCHARGING = 2;
	var NOT_CHARGING = 3;
	var FULL = 4;
}

enum abstract BatteryHealth(Int) from Int to Int
{
	var HEALTH_UNKNOWN = 0;
	var GOOD = 1;
	var OVERHEAT = 2;
	var DEAD = 3;
	var OVER_VOLTAGE = 4;
	var COLD = 5;
	var FAILURE = 6;
}

typedef BatterySnapshot =
{
	var percent:Int;
	var status:BatteryStatus;
	var health:BatteryHealth;
	var temperature:Float;
	var voltage:Float;
	var charging:Bool;
	var powerSaveMode:Bool;
	var timestamp:Float;
}

class Battery
{
	public static var instance(default, null):Battery;

	public static var onLowBattery(default, null):FlxSignal = new FlxSignal();
	public static var onCriticalBattery(default, null):FlxSignal = new FlxSignal();
	public static var onChargeStateChanged(default, null):FlxTypedSignal<Bool->Void> = new FlxTypedSignal<Bool->Void>();
	public static var onStatusChanged(default, null):FlxTypedSignal<BatteryStatus->Void> = new FlxTypedSignal<BatteryStatus->Void>();
	public static var onPercentChanged(default, null):FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	public static var onPowerSaveToggled(default, null):FlxTypedSignal<Bool->Void> = new FlxTypedSignal<Bool->Void>();

	public var lowBatteryThreshold:Int = 20;
	public var criticalBatteryThreshold:Int = 8;
	public var pollInterval:Float = 5.0;
	public var smoothingEnabled:Bool = true;
	public var smoothingSamples:Int = 5;

	var pollTimer:Float = 0;
	var samples:Array<Int> = [];
	var lastSnapshot:BatterySnapshot;
	var initialized:Bool = false;
	var lowFired:Bool = false;
	var criticalFired:Bool = false;

	public static function init():Void
	{
		if (instance != null)
			return;

		instance = new Battery();
		instance.setup();
	}

	function new() {}

	function setup():Void
	{
		lastSnapshot = readNativeSnapshot();
		samples.push(lastSnapshot.percent);
		initialized = true;

		#if android
		registerAndroidReceiver();
		#end
	}

	public static function update(elapsed:Float):Void
	{
		if (instance == null || !instance.initialized)
			return;

		instance.pollTimer += elapsed;

		if (instance.pollTimer >= instance.pollInterval)
		{
			instance.pollTimer = 0;
			instance.poll();
		}
	}

	function poll():Void
	{
		var snapshot = readNativeSnapshot();

		if (smoothingEnabled)
		{
			samples.push(snapshot.percent);

			if (samples.length > smoothingSamples)
				samples.shift();

			var sum = 0;

			for (s in samples)
				sum += s;

			snapshot.percent = Math.round(sum / samples.length);
		}

		evaluateTransitions(snapshot);
		lastSnapshot = snapshot;
	}

	function evaluateTransitions(snapshot:BatterySnapshot):Void
	{
		if (snapshot.percent != lastSnapshot.percent)
			onPercentChanged.dispatch(snapshot.percent);

		if (snapshot.status != lastSnapshot.status)
			onStatusChanged.dispatch(snapshot.status);

		if (snapshot.charging != lastSnapshot.charging)
			onChargeStateChanged.dispatch(snapshot.charging);

		if (snapshot.powerSaveMode != lastSnapshot.powerSaveMode)
			onPowerSaveToggled.dispatch(snapshot.powerSaveMode);

		if (snapshot.percent <= criticalBatteryThreshold && !snapshot.charging)
		{
			if (!criticalFired)
			{
				criticalFired = true;
				onCriticalBattery.dispatch();
			}
		}
		else
		{
			criticalFired = false;
		}

		if (snapshot.percent <= lowBatteryThreshold && !snapshot.charging)
		{
			if (!lowFired)
			{
				lowFired = true;
				onLowBattery.dispatch();
			}
		}
		else
		{
			lowFired = false;
		}
	}

	function readNativeSnapshot():BatterySnapshot
	{
		#if android
		return readAndroidSnapshot();
		#elseif ios
		return readIOSSnapshot();
		#else
		return readFallbackSnapshot();
		#end
	}

	#if android
	function readAndroidSnapshot():BatterySnapshot
	{
		var percent = 100;
		var status = BatteryStatus.UNKNOWN;
		var health = BatteryHealth.HEALTH_UNKNOWN;
		var temperature = 0.0;
		var voltage = 0.0;
		var charging = false;
		var powerSave = false;

		try
		{
			percent = androidmanager.Battery.getLevel();
			charging = androidmanager.Battery.isCharging();
			status = mapAndroidStatus(androidmanager.Battery.getStatus());
			health = mapAndroidHealth(androidmanager.Battery.getHealth());
			temperature = androidmanager.Battery.getTemperature() / 10.0;
			voltage = androidmanager.Battery.getVoltage() / 1000.0;
			powerSave = androidmanager.Battery.isPowerSaveMode();
		}
		catch (e:Dynamic)
		{
			var lime = readFallbackSnapshot();
			percent = lime.percent;
			charging = lime.charging;
			status = lime.status;
		}

		return {
			percent: percent,
			status: status,
			health: health,
			temperature: temperature,
			voltage: voltage,
			charging: charging,
			powerSaveMode: powerSave,
			timestamp: Date.now().getTime()
		};
	}

	function mapAndroidStatus(raw:Int):BatteryStatus
	{
		return switch (raw)
		{
			case 2: BatteryStatus.CHARGING;
			case 3: BatteryStatus.DISCHARGING;
			case 4: BatteryStatus.NOT_CHARGING;
			case 5: BatteryStatus.FULL;
			default: BatteryStatus.UNKNOWN;
		}
	}

	function mapAndroidHealth(raw:Int):BatteryHealth
	{
		return switch (raw)
		{
			case 2: BatteryHealth.GOOD;
			case 3: BatteryHealth.OVERHEAT;
			case 4: BatteryHealth.DEAD;
			case 5: BatteryHealth.OVER_VOLTAGE;
			case 6: BatteryHealth.FAILURE;
			case 7: BatteryHealth.COLD;
			default: BatteryHealth.HEALTH_UNKNOWN;
		}
	}

	function registerAndroidReceiver():Void
	{
		try
		{
			androidmanager.Battery.registerListener(onNativeBatteryEvent);
		}
		catch (e:Dynamic) {}
	}

	function onNativeBatteryEvent(percent:Int, charging:Bool):Void
	{
		pollTimer = pollInterval;
	}
	#end

	#if ios
	function readIOSSnapshot():BatterySnapshot
	{
		var level = System.batteryLevel != null ? System.batteryLevel : 1.0;

		return {
			percent: Math.round(level * 100),
			status: BatteryStatus.UNKNOWN,
			health: BatteryHealth.HEALTH_UNKNOWN,
			temperature: 0.0,
			voltage: 0.0,
			charging: false,
			powerSaveMode: false,
			timestamp: Date.now().getTime()
		};
	}
	#end

	function readFallbackSnapshot():BatterySnapshot
	{
		return {
			percent: 100,
			status: BatteryStatus.FULL,
			health: BatteryHealth.GOOD,
			temperature: 0.0,
			voltage: 0.0,
			charging: true,
			powerSaveMode: false,
			timestamp: Date.now().getTime()
		};
	}

	public static function getSnapshot():BatterySnapshot
	{
		if (instance == null)
			init();

		return instance.lastSnapshot;
	}

	public static function getPercent():Int
	{
		return getSnapshot().percent;
	}

	public static function isCharging():Bool
	{
		return getSnapshot().charging;
	}

	public static function getStatus():BatteryStatus
	{
		return getSnapshot().status;
	}

	public static function getHealth():BatteryHealth
	{
		return getSnapshot().health;
	}

	public static function getTemperature():Float
	{
		return getSnapshot().temperature;
	}

	public static function isPowerSaveMode():Bool
	{
		return getSnapshot().powerSaveMode;
	}

	public static function isLow():Bool
	{
		return instance != null && getSnapshot().percent <= instance.lowBatteryThreshold;
	}

	public static function isCritical():Bool
	{
		return instance != null && getSnapshot().percent <= instance.criticalBatteryThreshold;
	}

	public static function forceRefresh():Void
	{
		if (instance != null)
			instance.poll();
	}

	public static function toDebugString():String
	{
		var s = getSnapshot();
		return '${s.percent}% | status=${s.status} | health=${s.health} | temp=${s.temperature}C | charging=${s.charging} | powerSave=${s.powerSaveMode}';
	}
}
