[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [String]
    $EpicId,
    [Parameter(Mandatory=$false)]
    [String]
    $ConfigurationPath
)

function Get-EnvironmentsByProject($project)
{
  $Envs = @()
  $environments = Get-ChildItem -Directory -Path "$($ConfigurationPath)\$($project)"
  foreach($environment in $environments)
  {
    $configExc = "$($environment.FullName)\.noterraform"
    # if exc then skip the env
    if(Test-Path -Path $configExc)
    {
      continue;
    }
    $configFile = "$($environment.FullName)\release-config.yml"
    if(Test-Path -Path $configFile)
    {
      $Envs += $environment.Name
    }
  }
  return $Envs
}

Write-Output ""

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($env:PAT)")) }

$skipProjects = @('db-deployment')

$Uri = "https://dev.azure.com/dsec-labs/_apis/wit/workitems/{0}?api-version=6.0" -f $EpicId
$data = Invoke-RestMethod -uri $Uri -Headers $AzureDevOpsAuthenicationHeader -ContentType 'application/json' -Method Get

$FieldsMatches = $data.fields.'System.Description' | Select-String -Pattern 'buildId=(\d+)' -AllMatches | Select-Object -ExpandProperty matches | Sort-Object -Unique

foreach ($build in $FieldsMatches)
{
  $build = $build.Groups[1].Value
  $Uri = "https://dev.azure.com/dsec-labs/dscan/_apis/build/builds/{0}" -f $build
  $data = Invoke-RestMethod -uri $Uri -Headers $AzureDevOpsAuthenicationHeader -ContentType 'application/json' -Method Get

  $name = $data.definition.name
  if($name -in $skipProjects)
  {
    continue;
  }

  foreach ($tag in $data.tags)
  {
    if($tag.StartsWith('version'))
    {
      $ver = $tag.Split(' ')[1]
    }
  }

  $data = (@"
  - name: {0}
    buildId: {1}
    version: {2}
    deploy: true
"@ -f $name, $build, $ver)
  Write-Output $data

  if($null -ne $ConfigurationPath)
  {
    $data = @"
    environments:
"@
    Write-Output $data
    $Envs = Get-EnvironmentsByProject($name)
    foreach($environment in $Envs)
    {
      Write-Output ("    `- {0}" -f $environment)
    }
  }

  Write-Output ""
}
