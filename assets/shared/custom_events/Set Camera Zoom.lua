function onEvent(n, v1, v2)
	if n ~= 'Set Camera Zoom' then return end

	local stageData = callMethodFromClass("backend.StageData", 'getStageFile', {curStage})
	cancelTween('tag')
	doTweenZoom('tag','camGame',tonumber(v1) or stageData.defaultZoom,v2,'sineInOut')
	setProperty('defaultCamZoom', tonumber(v1) or stageData.defaultZoom)
end