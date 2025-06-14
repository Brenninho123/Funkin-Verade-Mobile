function onEvent(name, value1, value2)
    if name == 'Lyrics' then
        local text1, text2 = value1:match("([^,]*),?([^,]*)")
        local color1, color2 = value2:match("([^,]*),?([^,]*)")

        if text1 and text1 ~= "" then
            setTextString('lyric1', text1)
            setTextColor('lyric1', color1 or "FFFFFF")
            setProperty('lyric1.alpha', 1)
        else
            setTextString('lyric1', "")
            setProperty('lyric1.alpha', 0)
        end

        if text2 and text2 ~= "" then
            setTextString('lyric2', text2)
            setTextColor('lyric2', color2 or color1 or "FFFFFF")
            setProperty('lyric2.alpha', 1)
        else
            setTextString('lyric2', "")
            setProperty('lyric2.alpha', 0)
        end

        if value1 == "" and value2 == "" then
            runTimer('removeLyrics', 0.00001)
        end
    end
end

function onTimerCompleted(tag)
    if tag == 'removeLyrics' then
        setProperty('lyric1.alpha', 0)
        setProperty('lyric2.alpha', 0)
    end
end

function onCreate()
    makeLuaText('lyric1', '', screenWidth, 0, 500)
    addLuaText('lyric1')
    setTextSize('lyric1', 40)
    setProperty('lyric1.alpha', 0)

    makeLuaText('lyric2', '', screenWidth, 0, 570)
    addLuaText('lyric2')
    setTextSize('lyric2', 40)
    setProperty('lyric2.alpha', 0)
end
