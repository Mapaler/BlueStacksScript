#蓝叠模拟器的注册表键
$hdreg = Get-ItemProperty HKLM:\SOFTWARE\BlueStacks_nxt;
#从注册表获取ADB程序路径
$hdadb = Join-Path -Path $hdreg.InstallDir -ChildPath "HD-Adb.exe"
$devicePortPattern = "(emulator-(\d+))\s+device";
$emulators = &$hdadb devices | Where-Object { $_ -match $devicePortPattern} | ForEach-Object {
	$deviceName = $_ -replace $devicePortPattern,'$1'
	$localPort = [int]($_ -replace $devicePortPattern,'$2') + 1

	$d = @{DeviceName=$deviceName;Port=$localPort}
	$d
}
function Set-Proxy($emu){
	Write-Host "请先在 模拟器设置 中打开 高级-Android调试（ADB）" -ForegroundColor yellow
	$defaultDomain = "10.0.2.3"
	Write-Host "请输入你需要设置代理的 主机地址/IP。"
	Write-Information "蓝叠模拟器默认的真实主机 IP 为 $defaultDomain，推荐直接回车保持默认"
	$proxyIP = Read-Host "主机地址/IP"
	if ($proxyIP.length -eq 0) {$proxyIP = $defaultDomain}
	
	Write-Host "请输入你的 HTTP 代理服务器端口，请在你的代理服务上进行检查。"
	Write-Information "直接回车或输入 0 代表关闭模拟器的代理设置"
	$proxyPort = Read-Host "代理端口"
	$proxy = if (($proxyPort.length -eq 0) -or ($proxyPort -eq 0)) {
			Write-Host "关闭 $($emu.DisplayName) 代理"
			"`:0" 
		} else {
			$proxy = "$proxyIP`:$proxyPort"
			Write-Host "设置 $($emu.DisplayName) 代理为 $proxy"
			$proxy
		}

	$specificDevice = $null
	#如果传入了模拟器，就添加 -s 设备名 的参数，要注意以逗号分割为数组而不是空格的字符串
	if ($emu) {$specificDevice = "-s",$emu.DeviceName}
	
	$err = $( $output = &$hdadb $specificDevice shell settings put global http_proxy $proxy) 2>&1
	#Write-Host "标准输出" $output
	#Write-Host "标准错误" $err
	if ($err -like "error*") {
		Write-Host $err -ForegroundColor Red
		Write-Host "发生错误，请确保你在 模拟器设置 中打开了 高级-Android调试（ADB）" -ForegroundColor Red
		#$err
	} else {
		$output
	}
}
switch($emulators.length)  
{
    0 {
		Write-Host "未检测到模拟器，请先运行模拟器。"
		Exit
	}
    1 {
		Set-Proxy
	}
    default {
		#配置文件路径
		$conf = Get-Content -Path (Join-Path -Path $hdreg.UserDefinedDir -ChildPath "bluestacks.conf") -Encoding utf8 -Raw
		$emulators = $emulators | ForEach-Object {
			#搜索当前配置的端口
			$match = $conf -match "\bbst\.instance\.(?<InstanceName>\w+)\.adb_port=`"$($_.Port)`""
			if ($match) {
				$instanceName = $Matches.InstanceName
				$conf -match "\bbst\.instance\.$instanceName\.display_name=`"(?<DisplayName>.+)`"" > null
				$displayName = $Matches.DisplayName
				#$Asset = New-Object -TypeName PSObject
				$d = [ordered]@{DisplayName=$displayName;InstanceName=$instanceName}
				$_ | Add-Member -NotePropertyMembers $d -TypeName Asset
				$_
			}
		}
		Write-Host "检测到以下" $emulators.length "个模拟器正在运行"
		for($x=0; $x -lt $emulators.length; $x=$x+1)   
		{   
			Write-Host ($x+1) -ForegroundColor Yellow -NoNewline
			Write-Host ":" $emulators[$x].DeviceName "(" $emulators[$x].DisplayName ")" -ForegroundColor Green
		}
		$emuID = Read-Host "请输入你需要设置代理的模拟器编号"
		if (($emuID -le 0) -or ($emuID -gt $emulators.length)) {
			Write-Host "没有这个编号的模拟器"
			Exit
		} else {
			$emu = $emulators[$emuID-1]
			Set-Proxy($emu)
		}
	}
}