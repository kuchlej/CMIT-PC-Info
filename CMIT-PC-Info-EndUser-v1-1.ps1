$Computer = $env:Computername
$Result = "" | Select Username,UserDomain,Manufacturer,Processor,Memory,Serialnumber,CSName,InstallDate,Buildnumber,AVName,AVDate,DiskType,Space,Freespace ## Create Object to hold the data
$OS = Get-WmiObject Win32_OperatingSystem -ComputerName $Computer
$Serialnumber = Get-WmiObject win32_bios
$Frees = Get-WmiObject Win32_LogicalDisk -ComputerName $computer -Filter "DeviceID='C:'"|  % {[Math]::Round(($_.freespace / 1GB),2)}
$Space = Get-WmiObject Win32_LogicalDisk -ComputerName $computer -Filter "DeviceID='C:'"|  % {[Math]::Round(($_.size / 1GB),2)}
$Memory = (Get-WMIObject -class Win32_PhysicalMemory -ComputerName $Computer |Measure-Object -Property capacity -Sum | % {[Math]::Round(($_.sum / 1GB),2)})
$Processor = get-wmiobject win32_processor -ComputerName $computer 
#| Select-Object DeviceID, @{'Name'='(GB)'; 'Expression'={[math]::truncate($_.freespace / 1GB)}}
$Manufacturer = (Get-WmiObject -class Win32_bios -computer $computer)
$AV1 = Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiVirusProduct  -ComputerName $Computer
$AV2 = Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiVirusProduct  -ComputerName $Computer 
$Result.Manufacturer = $Manufacturer.Manufacturer
$Result.Processor = $Processor.Name
$Result.Memory = $Memory
$Result.CSName = $OS.CSName ## Add CSName to line1
$Result.Username = $env:USERNAME#retrieves username from whoami grabs the username ignores domain name
$Result.userdomain = $env:userdomain
$Result.InstallDate = $OS.ConvertToDateTime($OS.InstallDate).ToShortDateString() ## Add InstallDate to line2
$Result.Buildnumber = $OS.version
$Result.serialnumber = $Serialnumber.Serialnumber
$Result.AVName = $AV1.displayname
$Result.AVDate = $AV2.timestamp
$disk = Get-PhysicalDisk
$Result.DiskType = $disk[0].MediaType
$Result.Freespace = $Frees 
$Result.space = $Space
##Shouldn't be necessary, but blanks the Username field in the csv if you try to go directly off of calling $Result
$Array = @() ## Create Array to hold the Data
$Array += $Result ## Add the data to the array
$Array | Export-csv .\discovery.csv -Append
$Result

Get-WmiObject Win32_OperatingSystem | Select * | Out-File -filepath  .\$computer.txt
$disk | Out-File -filepath .\$computer.txt -append
Get-NetIPConfiguration  | Out-File -filepath  .\$computer.txt -append
Get-Printer | Out-File -filepath  .\$computer.txt -append
Get-WmiObject -ClassName Win32_MappedLogicalDisk | Out-File -filepath  .\$computer.txt -append
Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiVirusProduct | Out-File -filepath  .\$computer.txt -append

$filelist=".\$computer.txt", ".\discovery.csv"
$desktop=[Environment]::GetFolderPath("Desktop")
Compress-Archive -LiteralPath $filelist -DestinationPath "$desktop\FIT-Info-$computer.zip"
Remove-Item $filelist