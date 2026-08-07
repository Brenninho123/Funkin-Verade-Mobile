package mobile.backend;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.BatteryManager;

public class BatteryReceiver extends BroadcastReceiver
{
	private static volatile boolean registered = false;
	private static volatile int level = -1;
	private static volatile int scale = 100;
	private static volatile int status = BatteryManager.BATTERY_STATUS_UNKNOWN;
	private static volatile int health = BatteryManager.BATTERY_HEALTH_UNKNOWN;
	private static volatile int plugType = 0;
	private static volatile int temperature = -1;
	private static volatile int voltage = -1;
	private static volatile boolean present = false;
	private static final BatteryReceiver instance = new BatteryReceiver();

	public static void register(Context context)
	{
		if (registered || context == null)
			return;

		IntentFilter filter = new IntentFilter(Intent.ACTION_BATTERY_CHANGED);
		Intent sticky = context.getApplicationContext().registerReceiver(instance, filter);

		if (sticky != null)
			instance.onReceive(context, sticky);

		registered = true;
	}

	@Override
	public void onReceive(Context context, Intent intent)
	{
		level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1);
		scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, 100);
		status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, BatteryManager.BATTERY_STATUS_UNKNOWN);
		health = intent.getIntExtra(BatteryManager.EXTRA_HEALTH, BatteryManager.BATTERY_HEALTH_UNKNOWN);
		plugType = intent.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0);
		temperature = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1);
		voltage = intent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1);
		present = intent.getBooleanExtra(BatteryManager.EXTRA_PRESENT, false);
	}

	public static int getLevel()
	{
		return level;
	}

	public static int getScale()
	{
		return scale;
	}

	public static int getStatus()
	{
		return status;
	}

	public static int getHealth()
	{
		return health;
	}

	public static int getPlugType()
	{
		return plugType;
	}

	public static int getTemperature()
	{
		return temperature;
	}

	public static int getVoltage()
	{
		return voltage;
	}

	public static boolean isPresent()
	{
		return present;
	}

	public static boolean isCharging()
	{
		return status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL;
	}
}
