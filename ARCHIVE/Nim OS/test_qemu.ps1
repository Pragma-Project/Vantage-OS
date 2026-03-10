$proc = Start-Process -FilePath "C:\Program Files\qemu\qemu-system-x86_64.exe" -ArgumentList "-cdrom","nimos.iso","-serial","file:serial.log","-m","512M","-display","none" -PassThru
Start-Sleep -Seconds 5
Stop-Process -Id $proc.Id -Force
Get-Content serial.log
