return

;Automates quest action


QUEST_ST:
	Hotkey,IfWinActive,Dawn of the Dragons
		Hotkey,^F9,QUEST_ACT1,On
	Return

QUEST_EN:
	Hotkey,^F9,QUEST_ACT1,Off
	SetTimer,QUEST_TIMER,Off
	Return
	
QUEST_ACT1:
	Critical,On
	quest_state := !quest_state
	
	if !quest_state
	{
		SetTimer,QUEST_TIMER,Off
		TrayTip,NOTICE:,Automatic quest tool has been disabled
	} else {
		TrayTip,NOTICE:,Automatic quest tool has been enabled
		quest_retry := 5
		if quest_isinside()
		{
			quest_state := 2
			quest_retry := 3
		}
		ImageSearch,x,y,(rx(20)),(ry(675)),(rx(150)),(ry(745)),*10 *Trans0xFF00FF i/quest/redatk.png
		if !ErrorLevel
			quest_state := 3
		SetTimer,QUEST_TIMER,500
	}
	Critical,Off
	Return
	
	
	
;	ImageSearch,x,y,(rx(320)),(ry(340)),(rx(410)),(ry(380)),*5 *Trans0xFF00FF i/quest/reset.png
;	if !ErrorLevel
;		quest_state := 1
	
QUEST_TIMER:
	if !quest_state
		Return
	if (gethome())
		Return
	
	s := "QUEST state [" quest_state "] @ retry [" quest_retry "]"
	showtooltip(s)
	
	if (quest_state=1)
	{
		ImageSearch,x,y,(rx(634)),(ry(446)),(rx(664)),(ry(758)),*10 *Trans0xFF00FF i/quest/redatk.png
		if !ErrorLevel
		{
			clickpos(x,y)
			quest_state := 2
			quest_retry := 5
			return
		} else {
			clickrel(757,737)  ;scroll down
			Sleep 1000
		}
		quest_retry--
		if !quest_retry
		{
			quest_resetarea()
			Send {LButton Down}
			Sleep 100
			moverel(721,545)
			Sleep 500
			Send {LButton Up}
			Sleep 1000
			quest_retry := 3
			Return
		}
	}
	
	if (quest_state=2)
	{
		clickrel(440,715)                      ;Continuous click
		PixelGetColor,c,(rx(485)),(ry(712))    ;Check contineu button is gone
		if (c==0x444444)                       ;If so, go back.
		{
			quest_retry--
			if (quest_retry)  ;This ensures that you don't try to close too fast
				return        ;in case of a trailing miniboss
			Sleep 1000
			clickrel(685,713)
			quest_state := 1
			Return
		} else {
			;Check to see if we're actually fighting a boss
			ImageSearch,x,y,(rx(20)),(ry(675)),(rx(150)),(ry(745)),*10 *Trans0xFF00FF i/quest/redatk.png
			if !Errorlevel
			{
				quest_state := 3
				quest_retry := 5
				Return
			}
		}
	}
	
	if (quest_state=3)
	{
		clickrel(90,700)
		PixelGetColor,c,(rx(208)),(ry(707))
		if (c==0x454545)
		{
			clickrel(468,704)
			Sleep 1000
			quest_resetarea()
			Sleep 1000
			quest_state := 1
			quest_retry := 5
			
		}
	}
	Return


;-------------------------------------------------------------------------------	
;Zero if not inside a quest, nonzero if inside
quest_isinside()
{
	ggw()
	gethome()
	PixelGetColor,c1,(rx(276)),(ry(698))
	PixelGetColor,c2,(rx(304)),(ry(704))
	PixelGetColor,c3,(rx(291)),(ry(679))
	;showtooltip("[" c1 ":" c2 ":" c3 "]")
	if (c1==0x121212 && c2==0x161616 && c3==0x151515)
		return 1
	else
		return 0
}
	
quest_resetarea()
{
	clickrel(280,370)  ;clickreset
	Sleep 200
	clickrel(353,468)  ;reset confirm and/or notification acknowledge
	Sleep 200
	moverel(756,701)
}	
	
	
	