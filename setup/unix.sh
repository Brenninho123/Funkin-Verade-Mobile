#!/bin/sh
echo Making local haxelib and setting it up...
mkdir ~/haxelib && haxelib setup ~/haxelib

echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib install lime
haxelib install openfl
haxelib git flixel https://github.com/HaxeFlixel/flixel --skip-dependencies
haxelib install flixel-addons --skip-dependencies
haxelib install hscript-iris 1.1.3
haxelib install tjson 1.4.0
haxelib install hxdiscord_rpc 1.2.4
haxelib install hxvlc 2.0.1 --skip-dependencies
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis 22b1ce089dd924f15cdc4632397ef3504d464e90
haxelib git grig.audio https://gitlab.com/haxe-grig/grig.audio.git cbf91e2180fd2e374924fe74844086aab7891666
read -p "Press any key to continue. . ."
exit