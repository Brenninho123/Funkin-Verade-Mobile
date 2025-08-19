local playedVidStart = false
local playedVidEnd = false

function onStartCountdown()
	if checkFileExists('assets/videos/'..songName..'_cutscene.mp4', true) and (not playedVidStart and not seenCutscene) then
		playedVidStart = true
		startVideo(songName..'_cutscene', false)

		return Function_Stop
	end
	return Function_Continue
end

function onEndSong()
	if checkFileExists('assets/videos/'..songName..'_endCutscene.mp4', true) and not playedVidEnd then
		playedVidEnd = true
		startVideo(songName..'_endCutscene', false)

		return Function_Stop
	end
	return Function_Continue
end