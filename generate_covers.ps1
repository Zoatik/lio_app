# generate_covers.ps1
$root = "c:\Users\axelh\Desktop\cado_lio\lio_app"
$videoExt = @("*.mp4","*.mov","*.m4v")

Get-ChildItem -Path $root\medias -Recurse -File -Include $videoExt | ForEach-Object {
  $video = $_.FullName
  $dir = $_.DirectoryName
  $base = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
  $cover = Join-Path $dir ($base + "_cover.jpg")

  if (-not (Test-Path $cover)) {
    & ffmpeg -y -i $video -ss 00:00:00 -frames:v 1 -q:v 2 $cover | Out-Null
    Write-Host "Cover created: $cover"
  } else {
    Write-Host "Cover exists: $cover"
  }
}
