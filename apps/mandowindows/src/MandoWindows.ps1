$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Windows.Forms,System.Drawing -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public sealed class PadLamp : System.Windows.Forms.Control {
 private bool pressed;
 public bool Pressed { get { return pressed; } set { if(pressed!=value){pressed=value;Invalidate();} } }
 public PadLamp(){SetStyle(System.Windows.Forms.ControlStyles.AllPaintingInWmPaint | System.Windows.Forms.ControlStyles.UserPaint | System.Windows.Forms.ControlStyles.OptimizedDoubleBuffer,true);}
 protected override void OnPaint(System.Windows.Forms.PaintEventArgs e){base.OnPaint(e); e.Graphics.SmoothingMode=System.Drawing.Drawing2D.SmoothingMode.AntiAlias; using(var b=new System.Drawing.SolidBrush(pressed?System.Drawing.Color.LimeGreen:System.Drawing.Color.DimGray)){e.Graphics.FillEllipse(b,2,2,20,20);} if(pressed){using(var pen=new System.Drawing.Pen(System.Drawing.Color.DarkGreen,2)){e.Graphics.DrawEllipse(pen,2,2,20,20);}} }
}

public sealed class CursorHalo : System.Windows.Forms.Form {
 System.Windows.Forms.Timer clock=new System.Windows.Forms.Timer();System.Drawing.Point previous;DateTime moved=DateTime.UtcNow;bool idle;int layerTicks;bool running;
 [DllImport("user32.dll",SetLastError=true)] static extern bool SetWindowPos(IntPtr hwnd,IntPtr after,int x,int y,int cx,int cy,uint flags);
 void RestoreLayer(){if(!running || IsDisposed || !IsHandleCreated)return;SetWindowPos(Handle,new IntPtr(-1),0,0,0,0,0x0010|0x0001|0x0002|0x0040);}
 protected override void WndProc(ref System.Windows.Forms.Message m){if(m.Msg==0x21){m.Result=new IntPtr(3);return;}if(m.Msg==0x84){m.Result=new IntPtr(-1);return;}base.WndProc(ref m);}
 protected override bool ShowWithoutActivation {get{return true;}}
 protected override System.Windows.Forms.CreateParams CreateParams {get{var p=base.CreateParams;p.ExStyle|=0x08000000|0x20|0x80;return p;}}
 public CursorHalo(){FormBorderStyle=System.Windows.Forms.FormBorderStyle.None;ShowInTaskbar=false;TopMost=true;BackColor=System.Drawing.Color.Magenta;TransparencyKey=BackColor;ClientSize=new System.Drawing.Size(56,56);DoubleBuffered=true;clock.Interval=50;clock.Tick+=(a,b)=>{var pos=System.Windows.Forms.Cursor.Position;if(pos!=previous){previous=pos;moved=DateTime.UtcNow;}bool next=(DateTime.UtcNow-moved).TotalSeconds>1.2;if(next!=idle){idle=next;Invalidate();}Location=new System.Drawing.Point(pos.X-28,pos.Y-28);if(++layerTicks>=5){layerTicks=0;RestoreLayer();}};}
 public void Start(){previous=System.Windows.Forms.Cursor.Position;moved=DateTime.UtcNow;Location=new System.Drawing.Point(previous.X-28,previous.Y-28);running=true;layerTicks=0;Show();RestoreLayer();Invalidate();clock.Start();}
 public void Stop(){running=false;clock.Stop();Hide();}
 protected override void OnPaint(System.Windows.Forms.PaintEventArgs e){base.OnPaint(e);e.Graphics.SmoothingMode=System.Drawing.Drawing2D.SmoothingMode.AntiAlias;using(var pen=new System.Drawing.Pen(idle?System.Drawing.Color.OrangeRed:System.Drawing.Color.DeepSkyBlue,3)){e.Graphics.DrawEllipse(pen,7,7,40,40);}}
 protected override void Dispose(bool disposing){if(disposing)clock.Dispose();base.Dispose(disposing);}
}
public static class PadNative {
 [StructLayout(LayoutKind.Sequential)] public struct Joy { public uint size,flags,x,y,z,r,u,v,buttons,number,pov,res1,res2; }
 [DllImport("winmm.dll")] public static extern uint joyGetPosEx(uint id, ref Joy j);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f,int x,int y,int data,UIntPtr extra);
 [DllImport("user32.dll")] public static extern void keybd_event(byte key,byte scan,uint flags,UIntPtr extra);
 [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int key);


 static readonly object clickLock=new object();
 static readonly uint[] masks=new uint[2];static readonly uint[] devices=new uint[2];
 static readonly int[] generation=new int[2];static long heartbeat=Environment.TickCount;
 public static void Heartbeat(){System.Threading.Interlocked.Exchange(ref heartbeat,Environment.TickCount);}
 static bool Emergency(){return GetAsyncKeyState(119)<0 || unchecked((uint)(Environment.TickCount-System.Threading.Interlocked.Read(ref heartbeat)))>2000;}
 public static void CancelClicks(){lock(clickLock){for(int side=0;side<2;side++){generation[side]++;if(masks[side]!=0){masks[side]=0;Mouse(side==1?16u:4u,0,0,0);}}}}
 public static void BeginClick(uint id,uint mask,bool right){
  if(mask==0)return;int side=right?1:0;
  lock(clickLock){
   if(masks[side]!=0 && devices[side]==id){masks[side]|=mask;return;}
   if(masks[side]!=0){masks[side]=0;Mouse(right?16u:4u,0,0,0);}
   devices[side]=id;masks[side]=mask;int token=++generation[side];
   var thread=new System.Threading.Thread(()=>{
    try{while(true){lock(clickLock){if(token!=generation[side] || masks[side]==0)return;Joy j=Read(id);uint held=j.size==0?0:(j.buttons&masks[side]);if(Emergency())held=0;masks[side]=held;if(held==0){Mouse(right?16u:4u,0,0,0);return;}}System.Threading.Thread.Sleep(8);}}
    catch{lock(clickLock){if(token==generation[side] && masks[side]!=0){masks[side]=0;Mouse(right?16u:4u,0,0,0);}}}
   });thread.IsBackground=true;
   try{thread.Start();Mouse(right?8u:2u,0,0,0);}catch{masks[side]=0;generation[side]++;Mouse(right?16u:4u,0,0,0);throw;}
  }
 }

 public const uint RawPadId=0xfffffffe;

 static readonly object rawLock=new object();static readonly Joy[] rawStates=new Joy[3];static readonly long[] rawTimes=new long[3];
 public static int TransportPreference; // 0 automatic, 1 USB, 2 Bluetooth
 public static string RawTransport="Sin informes HID";
 public static void SetRaw(Joy state,int transport){if(transport<1 || transport>2)return;lock(rawLock){rawStates[transport]=state;rawTimes[transport]=Environment.TickCount;}}
 static bool Fresh(int transport){return rawStates[transport].size!=0 && unchecked((uint)(Environment.TickCount-rawTimes[transport]))<500;}
 public static Joy ReadRaw(){lock(rawLock){int t=TransportPreference;if(t==0)t=Fresh(1)?1:2;if(t<1 || t>2 || !Fresh(t)){RawTransport="Sin conexion HID del transporte seleccionado";return new Joy();}RawTransport=t==1?"USB - HID":"Bluetooth - HID";return rawStates[t];}}
 public static double Axis(double value,double center){double d=value-center;double range=d>=0?65535-center:center;if(range<=0)return 0;double n=Math.Max(-1,Math.Min(1,d/range));if(Math.Abs(n)<0.18)return 0;return Math.Sign(n)*Math.Pow((Math.Abs(n)-0.18)/0.82,2);}
 public static double[] Motion(double sx,double sy,double tx,double ty){return Math.Abs(sx)>0 || Math.Abs(sy)>0?new double[]{sx,sy}:new double[]{tx,ty};}
 public static Joy Read(uint id) { if(id==RawPadId)return ReadRaw();Joy j=new Joy();j.size=(uint)Marshal.SizeOf(typeof(Joy)); j.flags=255; if(joyGetPosEx(id,ref j)!=0)j.size=0;return j; }
 public static void Key(byte k,bool up){keybd_event(k,0,up?2u:0u,UIntPtr.Zero);}
 public static void Mouse(uint f,int x,int y,int d){mouse_event(f,x,y,d,UIntPtr.Zero);}
}

public sealed class DS4Touch : System.Windows.Forms.NativeWindow, IDisposable {
 [StructLayout(LayoutKind.Sequential)] struct RID { public ushort page,usage;public uint flags;public IntPtr target; }
 [DllImport("user32.dll")] static extern bool RegisterRawInputDevices(RID[] d,uint n,uint size);
 [DllImport("user32.dll")] static extern uint GetRawInputData(IntPtr h,uint command,IntPtr data,ref uint size,uint header);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern uint GetRawInputDeviceInfo(IntPtr device,uint command,System.Text.StringBuilder data,ref uint size);
 bool enabled; public bool Enabled {get{return enabled;}set{enabled=value;if(!value){touching=false;remX=remY=0;lock(movementLock){pendingX=pendingY=0;}}}} public double Sensitivity=1.0; public string Status="Esperando datos del panel PS4 USB/Bluetooth";
 readonly object movementLock=new object();double pendingX,pendingY;
 public double[] TakeMotion(){lock(movementLock){var result=new double[]{pendingX,pendingY};pendingX=pendingY=0;return result;}}
 bool touching;int lastX,lastY,lastId;IntPtr lastDevice;double remX,remY;
 public DS4Touch(IntPtr handle){AssignHandle(handle);RID[] d={new RID{page=1,usage=5,flags=0x100,target=handle}};if(!RegisterRawInputDevices(d,1,(uint)Marshal.SizeOf(typeof(RID))))Status="No se pudo registrar el lector del panel";}
 IntPtr cachedDevice;bool cachedSony;
 bool Sony(IntPtr device){if(device==cachedDevice)return cachedSony;uint n=0;GetRawInputDeviceInfo(device,0x20000007,null,ref n);if(n==0 || n>4096)return false;var b=new System.Text.StringBuilder((int)n+1);if(GetRawInputDeviceInfo(device,0x20000007,b,ref n)==0xffffffff)return false;string name=b.ToString().ToLowerInvariant();cachedDevice=device;cachedSony=name.Contains("vid_054c")&&(name.Contains("pid_05c4")||name.Contains("pid_09cc"));return cachedSony;}
 protected override void WndProc(ref System.Windows.Forms.Message m){
  if(m.Msg==0xff){try{Read(m.LParam);}catch{touching=false;Status="Error de lectura del panel";}}
  base.WndProc(ref m);
 }
 void Read(IntPtr raw){uint header=(uint)(8+2*IntPtr.Size),size=0;if(GetRawInputData(raw,0x10000003,IntPtr.Zero,ref size,header)==0xffffffff || size<header+8 || size>65536)return;IntPtr ptr=Marshal.AllocHGlobal((int)size);try{
 if(GetRawInputData(raw,0x10000003,ptr,ref size,header)==0xffffffff)return;
 if(Marshal.ReadInt32(ptr)!=2)return;IntPtr device=Marshal.ReadIntPtr(ptr,8);if(!Sony(device))return;
 byte[] b=new byte[size];Marshal.Copy(ptr,b,0,(int)size);int start=(int)header;uint len=BitConverter.ToUInt32(b,start),count=BitConverter.ToUInt32(b,start+4);if(len<10 || len>1024 || count>(size-header-8)/len)return;
 for(int i=0;i<count;i++){int o=start+8+i*(int)len;
 int state=0,transport=0;
 if(b[o]==1 && len>=10){state=o+1;transport=len>=43?1:2;}
 else if(b[o]>=17 && b[o]<=25 && len>=78 && (b[o+1]&128)!=0){state=o+3;transport=2;}
 else continue;
 PadNative.Joy snapshot=new PadNative.Joy();snapshot.size=52;snapshot.flags=255;
 snapshot.x=(uint)b[state]*257;snapshot.y=(uint)b[state+1]*257;snapshot.z=(uint)b[state+2]*257;snapshot.r=(uint)b[state+3]*257;
 snapshot.u=(uint)b[state+7]*257;snapshot.v=(uint)b[state+8]*257;
 snapshot.buttons=(uint)((b[state+4]>>4)|(b[state+5]<<4)|((b[state+6]&3)<<12));
 int direction=b[state+4]&15;snapshot.pov=direction<8?(uint)(direction*4500):65535;
 PadNative.SetRaw(snapshot,transport);
 if(PadNative.TransportPreference!=0 && PadNative.TransportPreference!=transport){touching=false;continue;}
 if(len < (uint)(state-o+42)){touching=false;Status="Bluetooth basico: botones disponibles, panel sin datos extendidos";continue;}
 o=state-1;bool active=(b[o+35]&128)==0;int id=b[o+35]&127;int x=b[o+36]|((b[o+37]&15)<<8),y=(b[o+37]>>4)|(b[o+38]<<4);if(x>1919 || y>941){touching=false;continue;}Status=active?"PANEL RECIBIDO - X:"+x+" Y:"+y:"Panel PS4 USB/Bluetooth detectado - sin contacto";
 if(!Enabled || !active){touching=false;remX=remY=0;continue;}
 if(touching && lastId==id && lastDevice==device){int dx=x-lastX,dy=y-lastY;if(Math.Abs(dx)<500 && Math.Abs(dy)<500){remX+=dx*Sensitivity;remY+=dy*Sensitivity;int mx=(int)remX,my=(int)remY;remX-=mx;remY-=my;lock(movementLock){pendingX=Math.Max(-200,Math.Min(200,pendingX+mx));pendingY=Math.Max(-200,Math.Min(200,pendingY+my));}}}
 touching=true;lastX=x;lastY=y;lastId=id;lastDevice=device;
 }
 }finally{Marshal.FreeHGlobal(ptr);}}
 public void Dispose(){RID[] d={new RID{page=1,usage=5,flags=1,target=IntPtr.Zero}};RegisterRawInputDevices(d,1,(uint)Marshal.SizeOf(typeof(RID)));ReleaseHandle();}
}

'@
$ErrorActionPreference='Stop'
$created=$false
$script:appMutex=New-Object System.Threading.Mutex($true,'Local\OpenApps.MandoWindows',[ref]$created)
if(-not $created){[Windows.Forms.MessageBox]::Show('MandoWindows ya esta abierto.','MandoWindows');$script:appMutex.Dispose();return}
try {
$path=Join-Path $env:LOCALAPPDATA 'MandoWindows'
$profile=Join-Path $path 'perfil.json'
$form=New-Object Windows.Forms.Form
$form.Text='Mando Windows v0.8-test - teclado y raton';$form.Size=New-Object Drawing.Size(680,1080);$form.StartPosition='CenterScreen'
$form.AutoScroll=$true
function Label($text,$x,$y,$w=550){$a=New-Object Windows.Forms.Label;$a.Text=$text;$a.Location=New-Object Drawing.Point($x,$y);$a.Size=New-Object Drawing.Size($w,24);$form.Controls.Add($a);return $a}
function Combo($items,$x,$y,$width=150){$a=New-Object Windows.Forms.ComboBox;$a.DropDownStyle='DropDownList';$a.Items.AddRange([object[]]$items);$a.SelectedIndex=0;$a.Location=New-Object Drawing.Point($x,$y);$a.Width=$width;$form.Controls.Add($a);return $a}
$null=Label 'USB o Bluetooth: conecta/empareja en Windows, mueve el mando y pulsa Detectar.' 15 12
$devices=Combo @('Sin detectar') 15 42 330
$scan=New-Object Windows.Forms.Button;$scan.Text='Detectar';$scan.Location=New-Object Drawing.Point(365,40);$form.Controls.Add($scan)
$transport=Combo @('Automatico','USB','Bluetooth') 455 42 180
$state=Label 'Control pausado. F8 pausa inmediatamente.' 15 78
$live=Label 'Entradas: ninguna' 15 104
$enabled=New-Object Windows.Forms.CheckBox;$enabled.Text='Activar teclado y raton';$enabled.Location=New-Object Drawing.Point(15,136);$enabled.Width=300;$form.Controls.Add($enabled)
$null=Label 'Palanca para cursor: ejes horizontal / vertical' 15 170
$axes=@('X','Y','Z','R','U','V');$ax=Combo $axes 15 200 100;$ay=Combo $axes 125 200 100;$ax.SelectedItem='Z';$ay.SelectedItem='R'
$cursor=New-Object Windows.Forms.CheckBox;$cursor.Text='Mover cursor';$cursor.Checked=$true;$cursor.Location=New-Object Drawing.Point(250,200);$cursor.Width=180;$form.Controls.Add($cursor)
$null=Label 'Velocidad (1-30)' 15 234 150
$speed=New-Object Windows.Forms.NumericUpDown;$speed.Minimum=1;$speed.Maximum=30;$speed.Value=12;$speed.Location=New-Object Drawing.Point(170,234);$form.Controls.Add($speed)
$null=Label 'Botones (el numero se ilumina al pulsarlo; no presupone modelo)' 15 380
$actions=@('Nada','Clic izquierdo','Clic derecho','Doble clic','Arriba','Abajo','Izquierda','Derecha','Copiar','Pegar','Cortar','Deshacer','Intro','Escape','Tab','Espacio','Rueda arriba','Rueda abajo')
$rows=@();$defaults=@('Copiar','Clic izquierdo','Clic derecho','Pegar')
for($i=0;$i -lt 16;$i++){ $col=[math]::Floor($i/8);$y=412+($i%8)*31;$x=15+$col*285;$lamp=New-Object PadLamp;$lamp.Location=New-Object Drawing.Point($x,$y);$lamp.Size=New-Object Drawing.Size(25,25);$form.Controls.Add($lamp);$lbl=Label ([string]($i+1)) ($x+27) $y 55;$cb=Combo $actions ($x+85) $y 180;if($i -lt 4){$cb.SelectedItem=$defaults[$i]};$rows+=@{label=$lbl;combo=$cb;lamp=$lamp} }
$save=New-Object Windows.Forms.Button;$save.Text='Guardar perfil';$save.Location=New-Object Drawing.Point(15,675);$save.Width=140;$form.Controls.Add($save)
$null=Label 'F8 pausa. Cerrar termina. No se inicia con Windows.' 15 712
$null=Label 'Mueve las palancas en pausa y ajusta ejes si hace falta.' 15 738
$null=Label 'Joystick fino: ejes horizontal / vertical y velocidad' 15 275
$ax2=Combo $axes 15 305 100;$ay2=Combo $axes 125 305 100;$ax2.SelectedItem='X';$ay2.SelectedItem='Y'
$speed2=New-Object Windows.Forms.NumericUpDown;$speed2.Minimum=1;$speed2.Maximum=30;$speed2.Value=3;$speed2.Location=New-Object Drawing.Point(250,305);$form.Controls.Add($speed2)
$cursor2=New-Object Windows.Forms.CheckBox;$cursor2.Text='Activar fino';$cursor2.Checked=$true;$cursor2.Location=New-Object Drawing.Point(390,305);$cursor2.Width=140;$form.Controls.Add($cursor2)
$null=Label 'Ambos funcionan juntos. Suelta las palancas antes de activar.' 15 342
$touchOn=New-Object Windows.Forms.CheckBox;$touchOn.Text='Panel PS4 USB/Bluetooth';$touchOn.Checked=$true;$touchOn.Location=New-Object Drawing.Point(15,780);$touchOn.Width=180;$form.Controls.Add($touchOn)
$touchSpeed=New-Object Windows.Forms.NumericUpDown;$touchSpeed.DecimalPlaces=1;$touchSpeed.Increment=[decimal]0.1;$touchSpeed.Minimum=[decimal]0.1;$touchSpeed.Maximum=5;$touchSpeed.Value=1;$touchSpeed.Location=New-Object Drawing.Point(210,780);$form.Controls.Add($touchSpeed)
$touchState=Label 'Esperando panel PS4 USB/Bluetooth...' 15 815
$null=Label 'Desliza un dedo para mover. Clic con los botones asignados.' 15 845
$touchReader=New-Object DS4Touch($form.Handle)
$script:remX=0.0;$script:remY=0.0
$script:ids=@();$script:last=[uint32]0;$script:held=@{};$script:centers=@{};$script:ticks=0;$script:misses=0;$script:lost=$false;$script:recheckAt=[DateTime]::MinValue
function Release-All {[PadNative]::CancelClicks();$script:held=@{};$script:last=0;$script:lastHat=0;$script:remX=0.0;$script:remY=0.0;if($touchReader){$touchReader.Enabled=$false}}
function Detect {Release-All;$enabled.Checked=$false;$devices.Items.Clear();$script:ids=@();for($i=0;$i -lt 16;$i++){if($transport.SelectedIndex -ne 0){continue};$j=[PadNative]::Read($i);if($j.size -ne 0){$script:ids+=$i;$null=$devices.Items.Add("Mando Windows ID $i (transporte no verificado)")}};if([PadNative]::ReadRaw().size){$script:ids+=[uint32]4294967294;$null=$devices.Items.Add('PS4 HID - '+[PadNative]::RawTransport)};if($script:ids.Count){$devices.SelectedIndex=0;$state.Text='DETECTADO - '+$script:ids.Count+' mando(s). Suelta palancas y pulsa Activar.';$state.ForeColor=[Drawing.Color]::DarkGreen}else{$null=$devices.Items.Add('Sin conexion del transporte elegido');$devices.SelectedIndex=0;$state.Text='Sin conexion. El selector no empareja Bluetooth. Empareja en Windows.';$state.ForeColor=[Drawing.Color]::Firebrick};$script:misses=0;$script:lost=$false}

$scan.Add_Click({Detect})
$transport.Add_SelectedIndexChanged({$enabled.Checked=$false;Release-All;[PadNative]::TransportPreference=$transport.SelectedIndex;$state.Text='Transporte cambiado. Pulsa Detectar. Empareja Bluetooth en Windows.'})
$devices.Add_SelectedIndexChanged({if($enabled.Checked){$enabled.Checked=$false};Release-All;if($devices.SelectedIndex -ge 0 -and $devices.SelectedIndex -lt $script:ids.Count -and $script:ids[$devices.SelectedIndex] -eq [uint32]4294967294){$ax.SelectedItem='Z';$ay.SelectedItem='R';$ax2.SelectedItem='X';$ay2.SelectedItem='Y';$state.Text='PS4 HID: derecha Z/R; izquierda X/Y. Ajustes anteriores de WinMM no se reutilizan.'}elseif($p){if($p.horizontal -in $axes){$ax.SelectedItem=$p.horizontal};if($p.vertical -in $axes){$ay.SelectedItem=$p.vertical};if($p.horizontal2 -in $axes){$ax2.SelectedItem=$p.horizontal2};if($p.vertical2 -in $axes){$ay2.SelectedItem=$p.vertical2}}})
$enabled.Add_CheckedChanged({Release-All;$script:centers=@{};if($enabled.Checked -and -not $script:ids.Count){$enabled.Checked=$false};if($enabled.Checked -and $script:ids.Count){$j=[PadNative]::Read($script:ids[$devices.SelectedIndex]);if($j.size){foreach($a in $axes){$script:centers[$a]=if($script:ids[$devices.SelectedIndex] -eq [uint32]4294967294){32896.0}else{32767.5}}}else{$enabled.Checked=$false}};$state.Text=if($enabled.Checked){'ACTIVO - F8 para pausar'}else{'PAUSADO - puedes comprobar las entradas'}})
$save.Add_Click({try{[IO.Directory]::CreateDirectory($path)|Out-Null;@{horizontal=$ax.SelectedItem;vertical=$ay.SelectedItem;speed=[int]$speed.Value;cursor=$cursor.Checked;horizontal2=$ax2.SelectedItem;vertical2=$ay2.SelectedItem;speed2=[int]$speed2.Value;cursor2=$cursor2.Checked;transport=$transport.SelectedIndex;touch=$touchOn.Checked;touchSpeed=[double]$touchSpeed.Value;halo=$haloOn.Checked;hat=@($hatRows|ForEach-Object {$_.combo.SelectedItem});buttons=@($rows|ForEach-Object {$_.combo.SelectedItem})}|ConvertTo-Json|ForEach-Object {$temp=Join-Path $path ('perfil-'+[guid]::NewGuid().ToString('N')+'.tmp');try{[IO.File]::WriteAllText($temp,$_,[Text.UTF8Encoding]::new($false));if(Test-Path -LiteralPath $profile){[IO.File]::Replace($temp,$profile,$null)}else{[IO.File]::Move($temp,$profile)}}finally{if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp}}};$state.Text=if($enabled.Checked){'ACTIVO - perfil guardado. F8 pausa.'}else{'PAUSADO - perfil guardado. Marca Activar.'}}catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message)}})
if(Test-Path -LiteralPath $profile){try{$p=$null;if((Get-Item -LiteralPath $profile).Length -gt 65536){throw 'Perfil demasiado grande'};$p=Get-Content -LiteralPath $profile -Raw|ConvertFrom-Json;if($null -ne $p.touch){$touchOn.Checked=[bool]$p.touch};if($p.touchSpeed){$touchSpeed.Value=[decimal][math]::Max(0.1,[math]::Min(5,[double]$p.touchSpeed))};if($p.horizontal -in $axes){$ax.SelectedItem=$p.horizontal};if($p.vertical -in $axes){$ay.SelectedItem=$p.vertical};$speed.Value=[math]::Max(1,[math]::Min(30,[int]$p.speed));$cursor.Checked=[bool]$p.cursor;if($p.horizontal2 -in $axes){$ax2.SelectedItem=$p.horizontal2};if($p.vertical2 -in $axes){$ay2.SelectedItem=$p.vertical2};if($p.speed2){$speed2.Value=[math]::Max(1,[math]::Min(30,[int]$p.speed2))};if($null -ne $p.cursor2){$cursor2.Checked=[bool]$p.cursor2};for($i=0;$i -lt [math]::Min(16,$p.buttons.Count);$i++){if($p.buttons[$i] -in $actions){$rows[$i].combo.SelectedItem=$p.buttons[$i]}}}catch{}}
function Action($name){if($name -eq 'Doble clic'){[PadNative]::Mouse(2,0,0,0);[PadNative]::Mouse(4,0,0,0);[PadNative]::Mouse(2,0,0,0);[PadNative]::Mouse(4,0,0,0);return};switch($name){'Copiar'{$k=67};'Pegar'{$k=86};'Cortar'{$k=88};'Deshacer'{$k=90};default{$k=0}};if($k){try{[PadNative]::Key(17,$false);[PadNative]::Key($k,$false)}finally{[PadNative]::Key($k,$true);[PadNative]::Key(17,$true)};return};$key=switch($name){'Arriba'{38};'Abajo'{40};'Izquierda'{37};'Derecha'{39};'Intro'{13};'Escape'{27};'Tab'{9};'Espacio'{32};default{0}};if($key){[PadNative]::Key($key,$false);[PadNative]::Key($key,$true)};if($name -eq 'Rueda arriba'){[PadNative]::Mouse(2048,0,0,120)};if($name -eq 'Rueda abajo'){[PadNative]::Mouse(2048,0,0,-120)}}

$null=Label 'Cruceta (POV) - configurable por direccion' 15 880
$hatRows=@();$hatNames=@('Arriba','Derecha','Abajo','Izquierda')
for($h=0;$h -lt 4;$h++){$xx=15+285*($h%2);$yy=910+34*[math]::Floor($h/2);$l=New-Object PadLamp;$l.Location=New-Object Drawing.Point($xx,$yy);$l.Size=New-Object Drawing.Size(25,25);$form.Controls.Add($l);$null=Label $hatNames[$h] ($xx+27) $yy 65;$c=Combo $actions ($xx+95) $yy 160;$c.SelectedItem=$hatNames[$h];$hatRows+=@{lamp=$l;combo=$c}}
$script:lastHat=0
$haloOn=New-Object Windows.Forms.CheckBox;$haloOn.Text='Activar resaltado del cursor (azul; naranja al estar quieto)';$haloOn.Location=New-Object Drawing.Point(15,985);$haloOn.Width=600;$form.Controls.Add($haloOn)
$halo=New-Object CursorHalo
$haloOn.Add_CheckedChanged({if($haloOn.Checked){$halo.Start()}else{$halo.Stop()}})
if($p){if($p.hat){for($h=0;$h -lt [math]::Min(4,$p.hat.Count);$h++){if($p.hat[$h] -in $actions){$hatRows[$h].combo.SelectedItem=$p.hat[$h]}}};$haloOn.Checked=[bool]$p.halo}

$timer=New-Object Windows.Forms.Timer;$timer.Interval=16
$timer.Add_Tick({try{[PadNative]::Heartbeat();$touchReader.Enabled=$enabled.Checked -and $touchOn.Checked;$touchReader.Sensitivity=[double]$touchSpeed.Value;$touchState.Text=$touchReader.Status+' | '+[PadNative]::RawTransport;if([PadNative]::GetAsyncKeyState(119) -lt 0 -and $enabled.Checked){$enabled.Checked=$false;$state.Text='PAUSADO por F8 - marca Activar para continuar.'};if(-not $script:ids.Count){if([DateTime]::UtcNow -gt $script:recheckAt){$script:recheckAt=[DateTime]::UtcNow.AddSeconds(1);Detect};return};$j=[PadNative]::Read($script:ids[$devices.SelectedIndex]);if(-not $j.size){$script:misses++;$enabled.Checked=$false;Release-All;foreach($row in $rows){$row.lamp.Pressed=$false};if($script:misses -ge 60){$enabled.Checked=$false;$script:lost=$true;$state.Text='SIN CONEXION - esperando USB/Bluetooth. Tras detectar, pulsa Activar.';$state.ForeColor=[Drawing.Color]::Firebrick}else{$state.Text='Conexion perdida - buscando de nuevo, sin enviar entradas.'};if([DateTime]::UtcNow -gt $script:recheckAt){$script:recheckAt=[DateTime]::UtcNow.AddSeconds(1);Detect};return};if($script:misses -gt 0){$script:misses=0;$state.ForeColor=[Drawing.Color]::DarkGreen;$state.Text=if($enabled.Checked){'ACTIVO - lectura recuperada. F8 pausa.'}else{'RECONECTADO - marca Activar para continuar.'};$script:last=$j.buttons};$hat=0;$pov=[uint32]$j.pov;if($pov -lt 36000){$sector=[int]([math]::Floor(($pov+2250)/4500)%8);$hat=switch($sector){0{1};1{3};2{2};3{6};4{4};5{12};6{8};7{9}}};for($h=0;$h -lt 4;$h++){$bit=1 -shl $h;$pressed=($hat -band $bit) -ne 0;$hatRows[$h].lamp.Pressed=$pressed;if($enabled.Checked -and $pressed -and (($script:lastHat -band $bit) -eq 0)){$hatAction=[string]$hatRows[$h].combo.SelectedItem;if($hatAction -eq 'Clic izquierdo'){[PadNative]::Mouse(2,0,0,0);[PadNative]::Mouse(4,0,0,0)}elseif($hatAction -eq 'Clic derecho'){[PadNative]::Mouse(8,0,0,0);[PadNative]::Mouse(16,0,0,0)}else{Action $hatAction}}};$script:lastHat=$hat;$script:ticks++;if($script:ticks%6 -eq 0){$live.Text="X:$($j.x) Y:$($j.y) Z:$($j.z) R:$($j.r) U:$($j.u) V:$($j.v)"};for($i=0;$i -lt 16;$i++){$mask=[uint32](1 -shl $i);$down=($j.buttons -band $mask) -ne 0;$was=($script:last -band $mask) -ne 0;$rows[$i].lamp.Pressed=$down;$rows[$i].label.BackColor=if($down){[Drawing.Color]::PaleGreen}else{[Drawing.SystemColors]::Control};if($enabled.Checked -and $down -and -not $was){$name=[string]$rows[$i].combo.SelectedItem;if($name -eq 'Clic izquierdo'){[PadNative]::BeginClick([uint32]$script:ids[$devices.SelectedIndex],$mask,$false);$script:held[$i]=$name}elseif($name -eq 'Clic derecho'){[PadNative]::BeginClick([uint32]$script:ids[$devices.SelectedIndex],$mask,$true);$script:held[$i]=$name}else{Action $name}};if(-not $down -and $script:held.ContainsKey($i)){$script:held.Remove($i)}};$script:last=$j.buttons;if($enabled.Checked){
 $dx=0.0;$dy=0.0
 foreach($stick in @(@{on=$cursor.Checked;h=$ax.SelectedItem;v=$ay.SelectedItem;speed=[double]$speed.Value},@{on=$cursor2.Checked;h=$ax2.SelectedItem;v=$ay2.SelectedItem;speed=[double]$speed2.Value})){
  if(-not $stick.on){continue};$values=@()
  foreach($axis in @($stick.h,$stick.v)){$values+=([PadNative]::Axis([double]$j.($axis.ToLower()),[double]$script:centers[$axis])*$stick.speed)}
  $dx+=$values[0];$dy+=$values[1]
 }
 $touchDelta=$touchReader.TakeMotion();$chosen=[PadNative]::Motion($dx,$dy,$touchDelta[0],$touchDelta[1]);$dx=$chosen[0];$dy=$chosen[1]
 if($dx -eq 0){$script:remX=0}else{$script:remX+=$dx};if($dy -eq 0){$script:remY=0}else{$script:remY+=$dy}
 $mx=[int][math]::Truncate($script:remX);$my=[int][math]::Truncate($script:remY)
 $script:remX-=$mx;$script:remY-=$my
 if($mx -or $my){[PadNative]::Mouse(1,$mx,$my,0)}
 }}catch{$enabled.Checked=$false;$state.ForeColor=[Drawing.Color]::Firebrick;$state.Text='PAUSADO por error: '+$_.Exception.Message;try{[IO.Directory]::CreateDirectory($path)|Out-Null;Add-Content -LiteralPath (Join-Path $path 'errores.log') -Value ((Get-Date -Format o)+' '+$_.Exception.ToString())}catch{}}})

function Release-WindowClicks { $previous=$script:last;Release-All;$script:last=$previous }
$form.Add_Deactivate({Release-WindowClicks})
$form.Add_Resize({if($form.WindowState -eq [Windows.Forms.FormWindowState]::Minimized){Release-WindowClicks}})

$form.Add_FormClosing({$timer.Stop();Release-All})
Detect
$timer.Start()
try{[Windows.Forms.Application]::Run($form)}finally{$timer.Stop();$touchReader.Enabled=$false;$touchReader.Dispose();$halo.Stop();$halo.Dispose();Release-All;$timer.Dispose();$form.Dispose()}

} finally { if($script:appMutex){$script:appMutex.ReleaseMutex();$script:appMutex.Dispose()} }
