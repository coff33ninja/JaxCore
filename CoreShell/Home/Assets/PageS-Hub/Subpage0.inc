[Variables]
Page.Items.H=(50*[Set.S])

; ---------------------------------------------------------------------------- ;
;                                  MeterStyle                                  ;
; ---------------------------------------------------------------------------- ; 

[Button.Shape:S]
X=((#Set.W#-#HomePage.P#*2-#Set.P#)/4+#Set.P#)r
Y=(-#Page.Items.H#/2)r
Shape=Rectangle 0,0,((#Set.W#-#HomePage.P#*2-#Set.P#)/2),#Page.Items.H#,(#Set.R#) | StrokeWidth (2*[Set.S]) | Extend This | Stroke Color #Set.Ter_Color#
This=Fill Color #Set.Sec_Color#
Container=#Sec.Container#
DynamicVariables=1
MouseOverAction=[!SetOption #CURRENTSECTION# This "Fill Color #Set.Ter_color#"][!UpdateMeter #CURRENTSECTION#][!Redraw]
MouseLeaveAction=[!SetOption #CURRENTSECTION# This "Fill Color #Set.Sec_Color#"][!UpdateMeter #CURRENTSECTION#][!Redraw]

[Button.String:S]
X=((#Set.W#-#HomePage.P#*2-#Set.P#)/4)r
Y=(#Page.Items.H#/2)r
Text=N/A
StringAlign=CenterCenter


; ---------------------------------------------------------------------------- ;
;                                    Content                                   ;
; ---------------------------------------------------------------------------- ;

[S-Hub.Image]
Meter=Image
X=(#Set.W#/2-128*[Set.S])
Y=(#Set.H#/2-128*[Set.S])
W=(256*[Set.S])
H=(256*[Set.S])
ImageName=#@#Images\CoreAssets\S-HubLogo256.png
Container=#Sec.Container#
DynamicVariables=1

[Button1.Shape]
Meter=Shape
X=#HomePage.P#
Y=(#Set.H#-#Sec.selector_height#-#Page.Items.H#-#Set.TitleBarH#-#Set.P#)
LeftMouseUpAction=[!WriteKeyValue Variables Page.SubPage "1" "#ROOTCONFIGPATH#CoreShell\Home\PageS-Hub.inc"][!Refresh]
MeterStyle=Button.Shape:S
[Button1.String]
Meter=String
Text=Share your setup!
MeterStyle=Set.String:S | Button.String:S
[Button2.Shape]
Meter=Shape
LeftMouseUpAction=[!WriteKeyValue Variables Page.SubPage "2" "#ROOTCONFIGPATH#CoreShell\Home\PageS-Hub.inc"][!Refresh]
MeterStyle=Button.Shape:S
[Button2.String]
Meter=String
Text=Import a setup!
MeterStyle=Set.String:S | Button.String:S
