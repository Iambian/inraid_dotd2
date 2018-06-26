;AutoHotkey main script for a collection of plugin-style scripts
;written for Dawn of the Dragons
;
;
;
;
;
;
;
;
;=============================================================================
;Performance options boilerplate
#NoEnv
#SingleInstance force
SendMode Input
SetWorkingDir %A_ScriptDir%
Thread,interrupt,0
#KeyHistory 10
#MaxThreads 255
#MaxMem 4095
#MaxThreadsBuffer On
#MaxHotkeysPerInterval 99000000
#HotkeyInterval 99000000
Process, Priority, , R
SetTitleMatchMode 2
SetKeyDelay, -1, -1, -1
SetMouseDelay, -1
SetWinDelay, -1
SetControlDelay, -1
#Persistent
;=============================================================================
isdebugging := 1
move_delay := 15
debug := 0
plugins := 0
hx := 0			;Coordinates for current location of home button. Set when
hy := 0			;gethome() function is run.
expx := 325     ;Coordinates for expected location of home button, used as a
expy := 137     ;reference point when winspy is used to grab pixel locations
;-----------------------------------------------------------------------------
register_plugin("TIERS")
;-----------------------------------------------------------------------------
start_plugin()
OnExit,CLEANUP
TrayTip,NOTICE:,DotD multitool is initialized and ready to go,10,1
Return

;=============================================================================
;Plugin includes
#include s\04_tiers.ahk

;=============================================================================
;Utility, miscellaneous, and maintenance
;----------------------
register_plugin(plugin_base_name)
{	;Example: register_plugin("WARCLICK")
	global
	plugins++
	plugin_%plugins% := plugin_base_name
}
;----------------------
start_plugin(name="")
{
	mod_plugin(name,"_ST")
}	
;----------------------
stop_plugin(name="")
{
	mod_plugin(name,"_EN")
}
;----------------------
mod_plugin(name,param)
{
	global
	local lbl
	if (name=="")
	{
		Loop,% plugins
		{
			lbl := plugin_%A_Index% . param
			Gosub,%lbl%
		}
	} else {
		lbl = name . param
		Gosub,%lbl%
	}
	return
}
;----------------------
;Get Game Window (info)
ggw()
{
	a:=WinExist("Dawn of the Dragons")
	WinGetTitle,b,ahk_id %a%
	if (b)
		WinActivate,%b%
	Sleep 100
	Return b
}
;----------------------
;Adjust X relative to last known home button location
rx(x)
{
	Global hx,expx
	Return (x-expx)+hx
}
;----------------------
;Adjust Y relative to last known home button location
ry(y)
{
	Global hy,expy
	Return (y-expy)+hy
}
;----------------------
;Click with position adjusted to last known home button location
clickrel(x,y)
{
	clickpos(rx(x),ry(y))
}
;----------------------
;Retrieves current position relative to last known home button location
getrel(ByRef x,ByRef y)
{
	MouseGetPos,tx,ty
	x = rx(tx)
	y = ry(ty)
}
;----------------------
;Moves mouse relative to last known home button location
moverel(x,y)
{
	MouseMove,(rx(x)),(ry(y))
}

;----------------------
;Click at X,Y using default coordinate system (current window)
clickpos(x,y)
{
	MouseMove,x,y
	Sleep,%move_delay%
	Click
}
;Convenience function
clickhere(x,y)
{
	clickpos(x,y)
}
;----------------------
;Debug: Show location of HOME button
showhome()
{
	gethome()
	showtooltip("Home at: [" hx "," hy "], expected: [" expx "," expy "]")
	Return
}
;----------------------
;Get home location, returns 0 if success, nonzero if failure.
;If success, automatically sets hx and hy variables
gethome()
{
	Global hx,hy
	ImageSearch,x,y,hx,hy,(hx+9),(hy+13),i/homeoff.bmp
	if (ErrorLevel)
	{
		ImageSearch,x,y,hx,hy,(hx+9),(hy+13),i/homeon.bmp
		if (ErrorLevel)
		{
			WinGetPos,wx,wy,ww,wh,A
			ImageSearch,x,y,0,0,ww,wh,i/homeoff.bmp
			if (ErrorLevel)
			{
				ImageSearch,x,y,0,0,ww,wh,i/homeon.bmp
				If (ErrorLevel)
					Return 1
			}
		}
	}
	hx := x
	hy := y
	Return 0
}
;----------------------
set_window_onclose(label)
{
	Global
	main_oncloselabel := label
}
GuiClose:
	Goto %main_oncloselabel%
;----------------------
;Show tooltip and automatically expire it in 5 seconds
showtooltip(s,x=1,y=1)
{
	ToolTip,%s%,x,y
	if (x==1 && y==1)
		SetTimer,EXPIRETIP,5000
	else
		SetTimer,EXPIRETIP,600
}
EXPIRETIP:
	SetTimer,EXPIRETIP,Off
	Sleep 200
	ToolTip
	Sleep 200
	ToolTip
	Return
;----------------------
F12::
	ExitApp
Pause::
	Reload
	Return
CLEANUP:
	stop_plugin()
	ExitApp
	
;----------------------
;DEBUGGING
ScrollLock::
	debug := !debug
	if (debug)
	{
		SetTimer,DEBUGGER,15
	} else {
		SetTimer,DEBUGGER,Off
		Sleep 200
		ToolTip, ,,,2
		Sleep 200
		ToolTip, ,,,2
	}
	return
DEBUGGER:
	MouseGetPos,dbgmx,dbgmy
	PixelGetColor,dbgcol,dbgmx,dbgmy
	if (gethome())
	{
		dbgstr := "Cannot find HOME button for calibration"
	} else {
		dbgstr := "Pos [" dbgmx "," dbgmy "], adjusted [" rx(dbgmx) "," ry(dbgmy) "] "
		dbgstr .= "Homepos [" hx "," hy "], color BGR: " dbgcol
	}
	ToolTip,%dbgstr%,0,16,2
	return

debug(s)
{
	Global
	if (isdebugging)
	{
		OutputDebug,%s%
	}
	
}
;###############################################################################
;The stuff below this line is written by some other guy. Found it via searching
;on the ahk forums. You should be able to find him too. That'll lead you to
;wherever credit is due for this section.

UrlDownloadToVar(URL, Proxy="", ProxyBypass="")
{
	AutoTrim, Off
	hModule := DllCall("LoadLibrary", "str", "wininet.dll") 

	If (Proxy != "")
	AccessType=3
	Else
	AccessType=1
	;INTERNET_OPEN_TYPE_PRECONFIG                    0   // use registry configuration
	;INTERNET_OPEN_TYPE_DIRECT                       1   // direct to net
	;INTERNET_OPEN_TYPE_PROXY                        3   // via named proxy
	;INTERNET_OPEN_TYPE_PRECONFIG_WITH_NO_AUTOPROXY  4   // prevent using java/script/INS

	io_hInternet := DllCall("wininet\InternetOpenA"
	, "str", "" ;lpszAgent
	, "uint", AccessType
	, "str", Proxy
	, "str", ProxyBypass
	, "uint", 0) ;dwFlags

	iou := DllCall("wininet\InternetOpenUrlA"
	, "uint", io_hInternet
	, "str", url
	, "str", "" ;lpszHeaders
	, "uint", 0 ;dwHeadersLength
	, "uint", 0x80000000 ;dwFlags: INTERNET_FLAG_RELOAD = 0x80000000 // retrieve the original item
	, "uint", 0) ;dwContext


	If (ErrorLevel != 0 or iou = 0) {
		DllCall("FreeLibrary", "uint", hModule)
		;Add in another method of trying to connect.
		;temp := URLDownloadToVar2(URL)
		return temp
	}

	VarSetCapacity(buffer, 512, 0)
	VarSetCapacity(NumberOfBytesRead, 4, 0)
	Loop
	{
		irf := DllCall("wininet\InternetReadFile", "uint", iou, "uint", &buffer, "uint", 512, "uint", &NumberOfBytesRead)
		NOBR = 0
		Loop 4  ; Build the integer by adding up its bytes. - ExtractInteger
			NOBR += *(&NumberOfBytesRead + A_Index-1) << 8*(A_Index-1)
		IfEqual, NOBR, 0, break
		;BytesReadTotal += NOBR
		DllCall("lstrcpy", "str", buffer, "uint", &buffer)
		res = %res%%buffer%
	}
	StringTrimRight, res, res, 2

	DllCall("wininet\InternetCloseHandle",  "uint", iou)
	DllCall("wininet\InternetCloseHandle",  "uint", io_hInternet)
	DllCall("FreeLibrary", "uint", hModule)
	AutoTrim, on
	return, res
}
