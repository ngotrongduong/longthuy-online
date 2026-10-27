$B = "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"
$W = "C:\Ai kiem tien\portfolio\rigged-fox\work"
foreach ($s in @("S1","S2","S3","S4","S8")) {
  & $B --background --factory-startup --python "$W\render.py" -- $s all 64 2>&1 | Select-String -Pattern "DONE|BEFORE_TRIS|Error|Traceback"
}
& $B --background --factory-startup --python "$W\assemble.py" 2>&1 | Select-String -Pattern "TOTAL|FFMPEG|MP4|rror"
& "$W\check_video.ps1"
