#Requires -Modules Az.Accounts, Az.Resources, Az.Websites
<#
.SYNOPSIS
  Deploys the Azure Infrastructure Summit site using a Deployment Stack.
.DESCRIPTION
  1. Sets the subscription context.
  2. Creates or updates a subscription-scoped Deployment Stack (infrastructure).
  3. Zips the website folder and publishes it to the App Service.
.PARAMETER SubscriptionId
  Target Azure subscription. Defaults to the project subscription.
.PARAMETER StackName
  Name of the Deployment Stack resource. Defaults to 'stack-summit'.
.PARAMETER Location
  Azure region for the stack metadata and all resources. Defaults to 'canadacentral'.
.PARAMETER ActionOnUnmanage
  What happens to resources removed from the template.
  'DetachAll' (default) leaves them in place; 'DeleteAll' destroys them.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string] $SubscriptionId,
  [string] $StackName       = 'stack-summit',
  [string] $Location        = 'canadacentral',
  [ValidateSet('DetachAll', 'DeleteAll', 'DeleteResources')]
  [string] $ActionOnUnmanage = 'DetachAll'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── 1. Subscription context ───────────────────────────────────────────────────

Write-Host "`n==> Setting subscription context..." -ForegroundColor Cyan
Set-AzContext -SubscriptionId $SubscriptionId | Out-Null

# ── 2. Deploy / update Deployment Stack ──────────────────────────────────────

Write-Host "==> Deploying infrastructure via Deployment Stack '$StackName'..." -ForegroundColor Cyan

$stack = Set-AzSubscriptionDeploymentStack `
  -Name                  $StackName `
  -Location              $Location `
  -TemplateFile          "$PSScriptRoot/main.bicep" `
  -TemplateParameterFile "$PSScriptRoot/main.bicepparam" `
  -DenySettingsMode      'None' `
  -ActionOnUnmanage      $ActionOnUnmanage `
  -Force

$webAppName         = $stack.Outputs['webAppName'].Value
$webAppUrl          = $stack.Outputs['webAppUrl'].Value
$resourceGroupName  = (Get-Content "$PSScriptRoot/main.bicepparam" | Select-String 'resourceGroupName').ToString() -replace ".*=\s*'([^']+)'.*", '$1'

Write-Host "    Web App : $webAppName" -ForegroundColor Gray
Write-Host "    URL     : $webAppUrl"  -ForegroundColor Gray

# ── 3. Package and publish website ────────────────────────────────────────────

Write-Host "==> Packaging website..." -ForegroundColor Cyan

$zipPath = "$PSScriptRoot/website.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

# Compress everything inside website/ so server.js sits at the zip root
$websiteItems = Get-ChildItem -Path "$PSScriptRoot/website" -Force
Compress-Archive -Path $websiteItems.FullName -DestinationPath $zipPath

Write-Host "==> Publishing to App Service..." -ForegroundColor Cyan
Publish-AzWebApp `
  -ResourceGroupName $resourceGroupName `
  -Name              $webAppName `
  -ArchivePath       $zipPath `
  -Force | Out-Null

Remove-Item $zipPath -Force

# ── Done ──────────────────────────────────────────────────────────────────────

Write-Host "`n✓ Deployment complete." -ForegroundColor Green
Write-Host "  Visit: $webAppUrl`n" -ForegroundColor Green
