$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$source=Join-Path $root 'src\MandoWindows.ps1'
$tokens=$null;$errors=$null
$null=[System.Management.Automation.Language.Parser]::ParseFile($source,[ref]$tokens,[ref]$errors)
if($errors.Count){throw ($errors|Out-String)}
$text=[IO.File]::ReadAllText($source)
$match=[regex]::Match($text,"(?s)-TypeDefinition @'\r?\n(.*?)\r?\n'@")
if(-not $match.Success){throw 'No se encuentra el bloque C#.'}
Add-Type -TypeDefinition $match.Groups[1].Value -ReferencedAssemblies System.Windows.Forms,System.Drawing
$csc=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if(-not(Test-Path $csc)){throw 'Requiere Windows x64 y el compilador .NET Framework.'}
$out=Join-Path $root ('dist\'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $out | Out-Null
$hash=(Get-FileHash $source -Algorithm SHA256).Hash.ToLowerInvariant()
$launcher=[IO.File]::ReadAllText((Join-Path $root 'src\Launcher.cs')).Replace('SOURCE_SHA256',$hash)
$temp=Join-Path $out 'Launcher.generated.cs'
[IO.File]::WriteAllText($temp,$launcher)
try{
 & $csc /nologo /target:winexe /platform:anycpu /reference:System.Windows.Forms.dll ('/win32manifest:'+(Join-Path $PSScriptRoot 'app.manifest')) ('/out:'+(Join-Path $out 'MandoWindows.exe')) $temp
 if($LASTEXITCODE -ne 0){throw 'Fallo al compilar el lanzador.'}
}finally{Remove-Item -LiteralPath $temp}
Copy-Item $source $out
Copy-Item (Join-Path $root 'src\Iniciar.cmd') $out
Copy-Item (Join-Path $root 'README.md') $out
Copy-Item (Join-Path $root 'LICENSE') $out
$hashes=Get-ChildItem $out -File|Sort-Object Name|ForEach-Object { (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()+'  '+$_.Name }
$hashes|Set-Content (Join-Path $out 'SHA256SUMS.txt') -Encoding ASCII
$zip=Join-Path $out 'MandoWindows-0.8-test-windows.zip'
Compress-Archive -LiteralPath @(Get-ChildItem $out -File|ForEach-Object {$_.FullName}) -DestinationPath $zip
Write-Host ('Paquete compilado, no firmado: '+$zip)
Write-Host ('SHA256 ZIP: '+(Get-FileHash $zip -Algorithm SHA256).Hash)
