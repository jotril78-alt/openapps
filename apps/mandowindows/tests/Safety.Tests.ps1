$ErrorActionPreference='Stop'
# Intercepts native IO to test the actual click ownership/worker implementation.
# No physical keyboard, mouse, gamepad or desktop effects in these tests.
$source=[IO.File]::ReadAllText((Join-Path $PSScriptRoot '..\src\MandoWindows.ps1'))
$start=$source.IndexOf('public static class PadNative {')
$end=$source.IndexOf('public sealed class DS4Touch',$start)
$native=$source.Substring($start,$end-$start)
$native=$native.Replace('public static class PadNative','public static class TestNative')
$native=[regex]::Replace($native,'\[DllImport\("winmm.dll"\)\] public static extern uint joyGetPosEx\(uint id, ref Joy j\);','public static uint joyGetPosEx(uint id, ref Joy j){ j.buttons=Buttons; return Connected?0u:1u; }')
$native=[regex]::Replace($native,'\[DllImport\("user32.dll"\)\] public static extern void mouse_event\(uint f,int x,int y,int data,UIntPtr extra\);','public static void mouse_event(uint f,int x,int y,int data,UIntPtr extra){ if(f==2)LeftDown++;if(f==4)LeftUp++;if(f==8)RightDown++;if(f==16)RightUp++; }')
$native=[regex]::Replace($native,'\[DllImport\("user32.dll"\)\] public static extern void keybd_event\(byte key,byte scan,uint flags,UIntPtr extra\);','public static void keybd_event(byte key,byte scan,uint flags,UIntPtr extra){}')
$native=[regex]::Replace($native,'\[DllImport\("user32.dll"\)\] public static extern short GetAsyncKeyState\(int key\);','public static short GetAsyncKeyState(int key){return Pause?(short)-1:(short)0;}')
$native=$native.Replace('public static class TestNative {','public static class TestNative { public static volatile uint Buttons; public static volatile bool Connected=true,Pause; public static int LeftDown,LeftUp,RightDown,RightUp;')
if($native.Contains('[DllImport')){throw 'Native call not mocked'}
Add-Type -TypeDefinition ("using System; using System.Runtime.InteropServices;`n"+$native)
function Check($condition,$message){if(-not $condition){throw $message};Write-Host ('OK '+$message)}
function Wait-Up($expected){$limit=[DateTime]::UtcNow.AddSeconds(1);while([TestNative]::LeftUp -lt $expected -and [DateTime]::UtcNow -lt $limit){Start-Sleep -Milliseconds 10}}
[TestNative]::CancelClicks()
Check ([TestNative]::LeftUp -eq 0) 'Startup does not release physical mouse buttons'
[TestNative]::Buttons=3;[TestNative]::Heartbeat();[TestNative]::BeginClick(0,1,$false);[TestNative]::BeginClick(0,2,$false)
Check ([TestNative]::LeftDown -eq 1) 'Two bindings own one mouse-down'
[TestNative]::Buttons=2;Start-Sleep -Milliseconds 50
Check ([TestNative]::LeftUp -eq 0) 'First binding release preserves second held binding'
[TestNative]::Buttons=0;Wait-Up 1
Check ([TestNative]::LeftUp -eq 1) 'Final binding release emits one mouse-up'
[TestNative]::Buttons=1;[TestNative]::Heartbeat();[TestNative]::BeginClick(0,1,$false);[TestNative]::Pause=$true;Wait-Up 2
Check ([TestNative]::LeftUp -eq 2) 'F8 releases without UI polling'
[TestNative]::Pause=$false;[TestNative]::Heartbeat();[TestNative]::BeginClick(0,1,$false);[TestNative]::Connected=$false;Wait-Up 3
Check ([TestNative]::LeftUp -eq 3) 'Disconnect releases owned click'
[TestNative]::Connected=$true;[TestNative]::Heartbeat();[TestNative]::BeginClick(0,1,$false);[TestNative]::CancelClicks();Wait-Up 4
Check ([TestNative]::LeftUp -eq 4) 'Cancel releases once'
[TestNative]::CancelClicks();Start-Sleep -Milliseconds 50
Check ([TestNative]::LeftUp -eq 4) 'Repeated cancellation does not release unowned clicks'
[TestNative]::Heartbeat();[TestNative]::BeginClick(0,1,$false);Start-Sleep -Milliseconds 2200
Check ([TestNative]::LeftUp -eq 5) 'Stalled UI watchdog releases owned click'
Write-Host 'Hardware acceptance tests remain manual.'

Check ([TestNative]::Axis(65535,32896) -gt 0.99) 'Raw right joystick reaches full right regardless of activation position'
Check ([TestNative]::Axis(0,32896) -lt -0.99) 'Raw left extent remains symmetric'
Check ([TestNative]::Axis(32896,32896) -eq 0) 'Raw midpoint does not drift'
$m=[TestNative]::Motion(4,0,-90,20)
Check ($m[0] -eq 4 -and $m[1] -eq 0) 'Stick movement suppresses conflicting touch displacement'
$m=[TestNative]::Motion(0,0,5,-2)
Check ($m[0] -eq 5 -and $m[1] -eq -2) 'Touch movement applies when sticks are centered'
$j=New-Object TestNative+Joy;$j.size=52;$j.x=111
[TestNative]::SetRaw($j,1);$j.x=222;[TestNative]::SetRaw($j,2)
[TestNative]::TransportPreference=1
Check ([TestNative]::ReadRaw().x -eq 111) 'Bluetooth report cannot overwrite USB selection'
[TestNative]::TransportPreference=2
Check ([TestNative]::ReadRaw().x -eq 222) 'USB report cannot overwrite Bluetooth selection'
[TestNative]::TransportPreference=0
Check ([TestNative]::ReadRaw().x -eq 111) 'Automatic mode prioritizes live USB reports'
Start-Sleep -Milliseconds 550
Check ([TestNative]::ReadRaw().size -eq 0) 'Stale reports are disconnected'
$j.x=333;[TestNative]::SetRaw($j,2)
Check ([TestNative]::ReadRaw().x -eq 333) 'Fresh Bluetooth is recovered after USB stops reporting'
