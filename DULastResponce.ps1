$recvFolder = '\\phm-los-ucomm01\c$\COM\AUS\DU\du_save\response'
$lastRecv = gci $recvFolder | Sort-Object LastWriteTime -Descending
$text = "$recvFolder\$($lastRecv[0])"

$lastErr = [IO.File]::ReadAllText($text)

write-host $lastErr