
param(
    [parameter(Mandatory=$true)]
    [String] $Name,
    [parameter(Mandatory=$true)]
    [String] $BuildId

)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($env:SYSTEM_ACCESSTOKEN)")) }

$Uri = "https://dev.azure.com/dsec-labs/dscan/_apis/build/builds/{0}" -f $BuildId
$data = Invoke-RestMethod -uri $Uri -Headers $AzureDevOpsAuthenicationHeader -Verbose -ContentType 'application/json' -Method Get
if($data.definition.name -ne $Name)
{
    Write-Output ("Project / Pipeline: {0}" -f $Name)
    Write-Output ("Build Id: {0}" -f $BuildId)
    Write-Output ("Build Pipeline Name: {0}" -f $data.definition.name)
    Write-Host "##vso[task.complete result=Failed;]Build Id is not of the project"
}

$Uri = "https://dev.azure.com/dsec-labs/dscan/_apis/pipelines?api-version=6.0-preview.1"
$data = Invoke-RestMethod -uri $Uri -Headers $AzureDevOpsAuthenicationHeader -Verbose -ContentType 'application/json' -Method Get

$pipeline_id = $data.value.GetEnumerator() | Where-Object { $_.name -eq $Name }

Write-Output "##vso[task.setvariable variable=pipeline_id]$($pipeline_id.id)"
Write-Output "##vso[task.setvariable variable=pipeline_id;isOutput=true]$($pipeline_id.id)"
