using System;
using System.IO;
using System.Diagnostics;
using System.Security.Cryptography;
using System.Windows.Forms;
internal static class Launcher {
 [STAThread] static int Main() {
  try {
   string script=Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"MandoWindows.ps1");
   if(!File.Exists(script))throw new FileNotFoundException("Falta MandoWindows.ps1 junto al ejecutable.");
   string actual;using(var sha=SHA256.Create())using(var file=File.OpenRead(script)){actual=BitConverter.ToString(sha.ComputeHash(file)).Replace("-","").ToLowerInvariant();}
   if(actual!="SOURCE_SHA256")throw new InvalidDataException("El script no coincide con esta compilacion. Descarga de nuevo el paquete oficial o recompila desde las fuentes.");
   string shell=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),@"WindowsPowerShell\v1.0\powershell.exe");
   var info=new ProcessStartInfo(shell,"-NoProfile -STA -ExecutionPolicy Bypass -File \""+script+"\"");
   info.UseShellExecute=false;info.CreateNoWindow=true;
   using(var process=Process.Start(info)){process.WaitForExit();if(process.ExitCode!=0)throw new Exception("MandoWindows termino con codigo "+process.ExitCode+". Ejecuta Iniciar.cmd para ver el error.");}
   return 0;
  } catch(Exception ex){MessageBox.Show(ex.Message,"Open Apps - MandoWindows",MessageBoxButtons.OK,MessageBoxIcon.Error);return 1;}
 }
}
