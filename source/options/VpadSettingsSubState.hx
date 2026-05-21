package options;

class VpadSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Language.getPhrase('options_Mobile', 'Controles de Celular');
		rpcTitle = 'Mobile Controls Menu';

		var option:Option = new Option(
			'Transparência dos Botões:',
			"Controla o quão transparente os Controles Virtuais devem ser.\nUm valor de 0% desativa os Controles Virtuais, permitindo apenas uso de controle ou teclado.",
			'vpadAlpha',
			PERCENT);
		option.defaultValue = 1;
		option.decimals = 0;
		option.onChange = () -> 
		{
			virtualPad.alpha = ClientPrefs.data.vpadAlpha;
			//virtualPad.exists = ClientPrefs.data.vpadAlpha > 0;
		}
		addOption(option);

		super();
	}
}