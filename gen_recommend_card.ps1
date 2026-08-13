Add-Type -AssemblyName System.Drawing

function Get-Base64Image($path, $width) {
  $img = [System.Drawing.Image]::FromFile($path)
  $h = [int]([Math]::Round($img.Height * $width / $img.Width))
  $bmp = New-Object System.Drawing.Bitmap($width, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.DrawImage($img, 0, 0, $width, $h)
  $ms = New-Object System.IO.MemoryStream
  $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
  $bytes = $ms.ToArray()
  $b64 = [Convert]::ToBase64String($bytes)
  $g.Dispose(); $bmp.Dispose(); $img.Dispose(); $ms.Dispose()
  return @($b64, $h)
}

$pocket = Get-Base64Image "C:\Users\TP\Desktop\source\opensource\pocket\images\title.jpg" 120
$bit = Get-Base64Image "C:\Users\TP\Desktop\source\opensource\Bit-Eye-Lib\image\All_faces_no_colour.png" 120

$pocketB64 = $pocket[0]; $pocketH = $pocket[1]
$bitB64 = $bit[0]; $bitH = $bit[1]

$utf8 = [System.Text.UTF8Encoding]::new($false)
$lines1 = [System.IO.File]::ReadAllLines("C:\Users\TP\Desktop\source\desc-pocket.txt", $utf8)
$lines2 = [System.IO.File]::ReadAllLines("C:\Users\TP\Desktop\source\desc-bit-eye.txt", $utf8)

function Build-Desc($lines, $yStart) {
  $sb = New-Object System.Text.StringBuilder
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $yy = $yStart + $i * 18
    [void]$sb.AppendLine("  <text x=`"148`" y=`"$yy`" class=`"desc`">$($lines[$i])</text>")
  }
  return $sb.ToString().TrimEnd()
}

$row1H = 30 + 18 * $lines1.Count
$row2H = 30 + 18 * $lines2.Count

$y1 = 4
$y2 = 4 + $row1H + 12
$height = $y2 + $row2H + 8

$pocketImgY = $y1 + [int](($row1H - $pocketH) / 2)
$bitImgY = $y2 + [int](($row2H - $bitH) / 2)

$desc1Html = Build-Desc $lines1 ($y1 + 48)
$desc2Html = Build-Desc $lines2 ($y2 + 48)

$svg = @"
<svg xmlns="http://www.w3.org/2000/svg" width="480" height="$height" viewBox="0 0 480 $height">
  <defs>
    <clipPath id="c1"><rect x="16" y="$pocketImgY" width="120" height="$pocketH" rx="10"/></clipPath>
    <clipPath id="c2"><rect x="16" y="$bitImgY" width="120" height="$bitH" rx="10"/></clipPath>
  </defs>
  <style>
    .title{font-family:'Segoe UI','Helvetica Neue',Arial,sans-serif;font-size:16px;font-weight:600;fill:#24292F}
    .name{font-family:'Segoe UI','Helvetica Neue',Arial,sans-serif;font-size:16px;font-weight:600;fill:#0969DA}
    .desc{font-family:'Segoe UI','Helvetica Neue','Microsoft YaHei',Arial,sans-serif;font-size:13px;fill:#57606A}
    @media (prefers-color-scheme: dark){
      .title{fill:#E6EDF3}
      .name{fill:#58A6FF}
      .desc{fill:#8B949E}
    }
  </style>
  <image href="data:image/png;base64,$pocketB64" x="16" y="$pocketImgY" width="120" height="$pocketH" clip-path="url(#c1)"/>
  <text x="148" y="$($y1 + 24)" class="name">Pocket</text>
$desc1Html
  <image href="data:image/png;base64,$bitB64" x="16" y="$bitImgY" width="120" height="$bitH" clip-path="url(#c2)"/>
  <text x="148" y="$($y2 + 24)" class="name">Bit-Eye</text>
$desc2Html
</svg>
"@

[System.IO.File]::WriteAllText("C:\Users\TP\Desktop\source\recommend-card.svg", $svg, [System.Text.UTF8Encoding]::new($false))
Write-Output "done $height"
