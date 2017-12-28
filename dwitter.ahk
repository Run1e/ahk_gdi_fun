/*
	u() is called as fast as possible.
	
	--- global constants ---
	t - time elapsed since script start (seconds)
	d - time elapsed since last frame (seconds, delta time)
	w - canvas width
	h - canvas height
	pi - 3.1415...
	g - GDI object
	
	--- functions ---
	f(Color) - Fill (or clear) canvas (Color is defaulted to 0x000000)
	sp(x, y, Color) - SetPixel
	dl(x1, y1, x2, y2, Color) - DrawLine
	fc(x, y, r, Color) - FillCircle
	fr(x, y, w, h, Color) - FillRectangle
	fe(x, y, w, h, Color) - FillEllipse
	r(r, g, b, brightness) - transform rbg values to hex
	h(hue, brightness) - get hue color from fraction. example: h(0) is red, h(1/3) is green and h(2/3) is blue.
	if not specified, Color is always defaulted to 0xFFFFFF (white)
	if not specified, brightness is always defaulted to 1
		
	--- shorthands ---
	s() - sin()
	c() - cos()
	t() - tan()
	a() - abs()
*/


; this is the function you overwrite!
u(){
	f(r(,20,40)),f=0
	while 17>++f,p:=s(t*3-f/9),a=0
		loop 16
			fc(w/2+s(r:=p+a++*pi/8)*f*h/35,h/2+c(r)*f*h/35,4,h(t/2+(16-f)/16))
}




/*
	=== BOILERPLATE BELOW ===
*/

#SingleInstance force
#NoEnv
#Persistent

SetWinDelay -1
SetBatchLines -1

global g, t, d
global pi := 3.14159265359
global w := 640
global h := 640

Gui, -MinimizeBox +Resize
Gui, Color, Black, Black
Gui, Margin, 0, 0
Gui, Add, Progress, % "hwndctrl BackgroundBlack x0 y0 w" w " h" h
Gui, Show

g := new GDI(ctrl, w, h)

SetTimer, FPS, 1000
DllCall("QueryPerformanceFrequency", "Int64P", freq)

Loop {
	t += d := (end - start) / freq
	DllCall("QueryPerformanceCounter", "Int64P", start)
	u()
	g.bitblt()
	DllCall("QueryPerformanceCounter", "Int64P", end)
	frames++
}

return

f(Color := 0x000000) {
	g.FillRectangle(0, 0, g.CliWidth, g.CliHeight, Color)
}

sp(x, y, Color := 0xFFFFFF) {
	g.SetPixel(x, y, Color)
}

dl(x1, y1, x2, y2, Color := 0xFFFFFF) {
	g.DrawLine(x1, y1, x2, y2, Color)
}

fc(x, y, r, Color := 0xFFFFFF) {
	g.FillEllipse(x, y, r*2, r*2, Color)
}

fr(x, y, w, h, Color := 0xFFFFFF) {
	g.FillRectangle(x, y, w, h, Color)
}

fe(x, y, w, h, Color := 0xFFFFFF) {
	g.FillEllipse(x, y, w, h, Color)
}

s(x) {
	return sin(x)
}

c(x) {
	return cos(x)
}

t(x) {
	return tan(x)
}

a(x) {
	return abs(x)
}

r(r := 0, g := 0, b := 0, brightness := 1) {
	return (b * brightness << 16) + (g * brightness << 8) + (r * brightness)
}

h(hue, brightness := 1) {
	if (hue<0,hue:=abs(mod(hue, 1)))
		hue:=1-hue
	Loop 3
		col+=max(min(-8*abs(mod(hue+A_Index/3-0.5,1)-0.5)+2.5,1),0)*255*brightness<<16-(A_Index-1)*8
	return col
}

min(Param*) {
	Out := Param.1
	for Index, Value in param
		if (Value < Out)
			Out := Value
	return Out
}

max(Param*) {
	Out := Param.1
	for Index, Value in Param {
		if (Value > Out)
			Out := Value
	} return Out
}

FPS:
Gui +LastFound
WinSetTitle,,,% "FPS: " frames
frames := 0
return

GuiClose:
GuiEscape:
ExitApp
return

GuiSize(hwnd, type, gw, gh) {
	global time
	w := gw, h:=gh
	GuiControl, Move, % g.hwnd, w%w% h%h%
	g.Resize(w, h)
	Sleep, -1
	u()
	g.bitblt()
}

class GDI
{
	__New(hWnd, CliWidth=0, CliHeight=0)
	{
		if !(CliWidth && CliHeight)
		{
			VarSetCapacity(Rect, 16, 0)
			DllCall("GetClientRect", "Ptr", hWnd, "Ptr", &Rect)
			CliWidth := NumGet(Rect, 8, "Int")
			CliHeight := NumGet(Rect, 12, "Int")
		}
		this.CliWidth := CliWidth
		this.CliHeight := CliHeight
		this.hWnd := hWnd
		this.hDC := DllCall("GetDC", "UPtr", hWnd, "UPtr")
		this.hMemDC := DllCall("CreateCompatibleDC", "UPtr", this.hDC, "UPtr")
		this.hBitmap := DllCall("CreateCompatibleBitmap", "UPtr", this.hDC, "Int", CliWidth, "Int", CliHeight, "UPtr")
		this.hOriginalBitmap := DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", this.hBitmap)
	}
	
	__Delete()
	{
		DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", this.hOriginalBitmap)
		DllCall("DeleteObject", "UPtr", this.hBitmap)
		DllCall("DeleteObject", "UPtr", this.hMemDC)
		DllCall("ReleaseDC", "UPtr", this.hWnd, "UPtr", this.hDC)
	}
	
	Resize(w, h)
	{
		this.CliWidth := w
		this.CliHeight := h
		
		this.hBitmap := DllCall("CreateCompatibleBitmap", "UPtr", this.hDC, "Int", w, "Int", h, "UPtr")
		hPrevBitmap := DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", this.hBitmap)
		DllCall("DeleteObject", "UPtr", hPrevBitmap)
	}
	
	BitBlt(x=0, y=0, w=0, h=0)
	{
		w := w ? w : this.CliWidth
		h := h ? h : this.CliHeight
		
		DllCall("BitBlt", "UPtr", this.hDC, "Int", x, "Int", y
		, "Int", w, "Int", h, "UPtr", this.hMemDC, "Int", 0, "Int", 0, "UInt", 0xCC0020) ;SRCCOPY
	}
	
	; DrawLine
	DrawLine(x, y, x2, y2, Color)
	{
		Pen := new GDI.Pen(Color)
		DllCall("MoveToEx", "UPtr", this.hMemDC, "Int", this.TranslateX(x), "Int", this.TranslateY(y), "UPtr", 0)
		hOriginalPen := DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", Pen.Handle, "UPtr")
		DllCall("LineTo", "UPtr", this.hMemDC, "Int", this.TranslateX(x2), "Int", this.TranslateY(y2))
		DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", hOriginalPen, "UPtr")
	}
	
	; SetPixel
	SetPixel(x, y, Color)
	{
		x := this.TranslateX(x)
		y := this.TranslateY(y, this.Invert) ; Move up 1 px if inverted (drawing "up" instead of down)
		DllCall("SetPixelV", "UPtr", this.hMemDC, "Int", x, "Int", y, "UInt", Color)
	}
	
	FillRectangle(x, y, w, h, Color, BorderColor=-1)
	{
		if (w == 1 && h == 1)
			return this.SetPixel(x, y, Color)
		
		Pen := new this.Pen(BorderColor < 0 ? Color : BorderColor)
		Brush := new this.Brush(Color)
		
		; Replace the original pen and brush with our own
		hOriginalPen := DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", Pen.Handle, "UPtr")
		hOriginalBrush := DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", Brush.Handle, "UPtr")
		
		x1 := this.TranslateX(x)
		x2 := this.TranslateX(x+w)
		y1 := this.TranslateY(y)
		y2 := this.TranslateY(y+h)
		
		DllCall("Rectangle", "UPtr", this.hMemDC
		, "Int", x1, "Int", y1
		, "Int", x2, "Int", y2)
		
		; Reselect the original pen and brush
		DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", hOriginalPen, "UPtr")
		DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", hOriginalBrush, "UPtr")
	}
	
	FillEllipse(x, y, w, h, Color, BorderColor=-1)
	{
		Pen := new this.Pen(BorderColor < 0 ? Color : BorderColor)
		Brush := new this.Brush(Color)
		
		; Replace the original pen and brush with our own
		hOriginalPen := DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", Pen.Handle, "UPtr")
		hOriginalBrush := DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", Brush.Handle, "UPtr")
		
		x1 := this.TranslateX(x)
		x2 := this.TranslateX(x+w)
		y1 := this.TranslateY(y)
		y2 := this.TranslateY(y+h)
		
		DllCall("Ellipse", "UPtr", this.hMemDC
		, "Int", x1, "Int", y1
		, "Int", x2, "Int", y2)
		
		; Reselect the original pen and brush
		DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", hOriginalPen, "UPtr")
		DllCall("SelectObject", "UPtr", this.hMemDC, "UPtr", hOriginalBrush, "UPtr")
	}
	
	TranslateX(X)
	{
		return Floor(X)
	}
	
	TranslateY(Y, Offset=0)
	{
		if this.Invert
			return this.CliHeight - Floor(Y) - Offset
		return Floor(Y)
	}
	
	class Pen
	{
		__New(Color, Width=1, Style=0)
		{
			this.Handle := DllCall("CreatePen", "Int", Style, "Int", Width, "UInt", Color, "UPtr")
		}
		
		__Delete()
		{
			DllCall("DeleteObject", "UPtr", this.Handle)
		}
	}
	
	class Brush
	{
		__New(Color)
		{
			this.Handle := DllCall("CreateSolidBrush", "UInt", Color, "UPtr")
		}
		
		__Delete()
		{
			DllCall("DeleteObject", "UPtr", this.Handle)
		}
	}
}