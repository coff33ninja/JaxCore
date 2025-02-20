; ---------------------------------------------------------------------------- ;
;                                   Function                                   ;
; ---------------------------------------------------------------------------- ;

[Variables]
TweenNode1=0
Sec.LatestCoreVer=N/A

; [MeasureOnLoad]
; Measure=Calc
; Formula=Counter
; IfEqualValue=1
; IfEqualAction=[!EnableMeasureGroup BackgroundMeasures]
; UpdateDivider=-1

; -------------------------------- News and page update check -------------------------------- ;

[NewsParser]
Measure=WebParser
URL=https://raw.githubusercontent.com/Jax-Core/JaxCore/main/CoreWebResources.inc
RegExp=(?siU).*NewsID=(.+)Page2ID=(.+)Page3ID=(.+)$
Group=BackgroundMeasures
Disabled=(0)
FinishAction=[!CommandMeasure LogicalScript "checkNews()"]

[mNewsID]
Measure=WebParser
URL=[NewsParser]
Group=BackgroundMeasures
Disabled=(0)
StringIndex=1

[mPage2ID]
Measure=WebParser
URL=[NewsParser]
Group=BackgroundMeasures
Disabled=(0)
StringIndex=2

[mPage3ID]
Measure=WebParser
URL=[NewsParser]
Group=BackgroundMeasures
Disabled=(0)
StringIndex=3

[ParseNews]
Measure=WebParser
URL=https://raw.githubusercontent.com/Jax-Core/JaxCore/main/Accessories/Popup/Variants/CoreNews.inc
CodePage=1200
RegExp=(?siU).*
Debug=2
Debug2File=#ROOTCONFIGPATH#Accessories\Popup\Variants\CoreNews.inc
DynamicVariables=1
Disabled=1
Group=ParseNews
FinishAction=[!Delay 1000][!commandMeasure Func "startPopup('CoreNews', 'Left')"]

[ParsePage2]
Measure=WebParser
URL=https://raw.githubusercontent.com/Jax-Core/JaxCore/main/CoreShell/Home/Page2.inc
CodePage=1200
RegExp=(?siU).*
Debug=2
Debug2File=#ROOTCONFIGPATH#CoreShell/Home/Page2.inc
DynamicVariables=1
Disabled=1

[ParsePage3]
Measure=WebParser
URL=https://raw.githubusercontent.com/Jax-Core/JaxCore/main/CoreShell/Home/Page3.inc
CodePage=1200
RegExp=(?siU).*
Debug=2
Debug2File=#ROOTCONFIGPATH#CoreShell/Home/Page3.inc
DynamicVariables=1
Disabled=1

; ------------------------------- Version check ------------------------------ ;

[WebParser]
Measure=WebParser
URL=https://raw.githubusercontent.com/Jax-Core/JaxCore/main/%40Resources/Version.inc
RegExp==(.*)$
Group=BackgroundMeasures
Disabled=(0)
FinishAction=[!CommandMeasure LogicalScript "check()"]
CodePage=1200

[mVer]
Measure=WebParser
URL=[WebParser]
Group=BackgroundMeasures
Disabled=(0)
StringIndex=1
CodePage=1200

[Toaster]
Measure=Plugin
Plugin=RunCommand
Program="#@#Addons\Toast\RainToaster.exe"
Parameter=--programpath "#PROGRAMPATH#Rainmeter.exe" --text "Available JaxCore update!" --text "JaxCore v#Sec.LatestCoreVer# is now available." --logo "JaxCore.png" --button "Install" "[!WriteKeyvalue Variables Skin.name #JaxCore \"#@#SecVar.inc\"][!WriteKeyvalue Variables Skin.Set_Page General \"#@#SecVar.inc\"][!ActivateConfig \"#JaxCore\Main\" \"Settings.ini\"]" --button "Dismiss"
DynamicVariables=1

[LogicalScript]
Measure=Script
ScriptFile=#ROOTCONFIGPATH#Accessories\UpdatePrompt\Logic.lua

; ---------------------------------------------------------------------------- ;
;                                    Content                                   ;
; ---------------------------------------------------------------------------- ;

[DefaultStartActions]
DynamicVariables=1

; ---------------------------------------------------------------------------- ;
;                                    Content                                   ;
; ---------------------------------------------------------------------------- ;

[B]
Shape2=Rectangle 0,0, #Set.W#, #Set.H#, #Set.WinR# | StrokeWidth 0 | Fill RadialGradient This
This=0,(#set.H#/2),0,0,(#Set.H#/2),(#Set.H#/2) | #Set.Pri_Color#,50 ; 1 | #Set.Accent_Color#,50 ; 0

[Loading.Image]
Meter=Image
X=([BC:W]/2-128/2*[SEt.S])
Y=([BC:H]/2-128/2*[SEt.S])
W=(128*[Set.S])
H=(128*[Set.S])
DynamicVariables=1
Container=BC
Group=Anim
ImageName=#@#Images\CoreAssets\LogoIcon.png