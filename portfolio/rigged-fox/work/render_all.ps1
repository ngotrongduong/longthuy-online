$B = "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
$W = "C:\Ai kiem tien\portfolio\rigged-fox\work"
$log = "$W\render_all.log"
"start $(Get-Date)" | Out-File $log
foreach ($s in @("S1","S2","S3","S4","S5","S6","S7","S8")) {
  & $B --background --factory-startup --python "$W\render.py" -- $s all 64 2>&1 | Select-String -Pattern "DONE|BEFORE_TRIS|Error|Traceback" | Out-File $log -Append
}
& $B --background --factory-startup --python "$W\render.py" -- still1 1 128 final 2>&1 | Select-String -Pattern "DONE|Error|Traceback" | Out-File $log -Append
& $B --background --factory-startup --python "$W\render.py" -- still2 1 128 final 2>&1 | Select-String -Pattern "DONE|Error|Traceback" | Out-File $log -Append
& $B --background --factory-startup --python "$W\render.py" -- still3 8 128 final 2>&1 | Select-String -Pattern "DONE|Error|Traceback" | Out-File $log -Append
"end $(Get-Date)" | Out-File $log -Append
