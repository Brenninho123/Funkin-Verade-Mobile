@echo off
echo Making local haxelib and setting it up...
mkdir .haxelib && haxelib setup .haxelib

echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib install lime 8.2.2
haxelib install openfl 9.4.1
haxelib install flixel 6.1.0 --skip-dependencies
haxelib install flixel-addons 3.3.2 --skip-dependencies
haxelib install hscript-iris 1.1.3
haxelib install tjson 1.4.0
haxelib install hxdiscord_rpc 1.2.4
haxelib install hxvlc 2.0.1 --skip-dependencies
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate b8970d2e4d875c743abe28e356a15413b1774d94
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit daf0664aee99aa8b8d6bdd1eda993a1c3a399067
pause
