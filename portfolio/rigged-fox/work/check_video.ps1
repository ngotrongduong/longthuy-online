$F = "C:\Users\ngotr\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-9.0.2-full_build\bin\ffmpeg.exe"
$P = "C:\Users\ngotr\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-9.0.2-full_build\bin\ffprobe.exe"
$V = "C:\Ai kiem tien\portfolio\rigged-fox-demo.mp4"
$O = "C:\Ai kiem tien\portfolio\rigged-fox\work\check"
New-Item -ItemType Directory -Force $O | Out-Null
& $P -v error -show_entries stream=codec_name,width,height,pix_fmt,r_frame_rate,nb_frames -show_entries format=duration,size -of compact $V
foreach ($t in @("1.2","2.8","5.0","8.0","11.5","14.5","17.6","20.2","22.6")) {
  & $F -y -v error -ss $t -i $V -frames:v 1 "$O\t_$t.png"
}
