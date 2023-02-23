
param(
    [parameter(Mandatory=$true)]
    [String] $Version,
    [parameter(Mandatory=$true)]
    [String] $File
)

$r1 = Get-Content -Path $File
$r2 = $r1 |  Select-String -Pattern $Version -Quiet

if($r2 -eq $True)
{
  Write-Output ("[OK] Got version {0}" -f $Version)
} else
{
  Write-Output ("[Error] Version mismatch {0} -ne {1}" -f $Version, $r1)
  Write-Host "##vso[task.complete result=Failed;]Failed"
}
