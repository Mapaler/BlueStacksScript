#获取输入的操作
$operate = Read-Host "请输入数字(0:关闭/1:打开)root"
#转换为数字
$root = [convert]::ToInt16($operate)
#蓝叠模拟器的注册表键
$hdreg = Get-ItemProperty HKLM:\SOFTWARE\BlueStacks_nxt;
#配置文件路径
$confPath = Join-Path -Path $hdreg.UserDefinedDir -ChildPath "bluestacks.conf"
Write-Host "配置文件路径为：$confPath"
#获取配置文件的对象
$file = Get-Item $confPath
#获取文件内容
$conf = Get-Content -Path $file -Encoding utf8
#正则表达式替换文件 root 值
$conf = $conf -replace "^(bst\.(?:feature\.rooting|instance\.Nougat64(?:_\d+)?\.enable_root_access))=`"\d`"", "`$1=`"$root`""
#先以Linux换行符合并后，再强制写入文件（覆盖只读），但是 PS 5.1 不支持 utf8noBom，导致蓝叠无法识别，因此无法使用
#$conf -join "`n" | Out-File -FilePath $file -Encoding utf8NoBOM -Force -NoNewline
#先关掉文件的只读才能进行写入
$file.IsReadOnly = $false
#建立 Utf8NoBom 的参数对象
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[IO.File]::WriteAllText($file, ($conf -join "`n") + "`n", $Utf8NoBomEncoding)
#打开 root 后设置为只读模式
if ($root) {$file.IsReadOnly = $true}
Write-Host "$(If ($root) {"打开"} else {"关闭"}) root 设置完毕，请重新启动蓝叠模拟器"