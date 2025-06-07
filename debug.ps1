# Replace these with your actual values
$adoOrg = "your-org"         # Example: contoso
$adoProject = "your-project" # Example: DevOpsTest
$wikiName = "your-wiki"      # Example: MyProjectWiki
$adoPat = "your-azure-pat"

# Basic Auth Header
$base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$adoPat"))
$authHeader = @{ Authorization = "Basic $base64Auth" }

# Build URL
$url = "https://dev.azure.com/$adoOrg/$adoProject/_apis/wiki/wikis/$wikiName/pages?api-version=6.0&recursionLevel=Full"

Write-Host "`n🔎 Requesting pages from:"
Write-Host $url -ForegroundColor Cyan

# Try the API call
try {
    $response = Invoke-RestMethod -Uri $url -Headers $authHeader -ErrorAction Stop
    if ($response.count -eq 0 -or -not $response.value) {
        Write-Host "⚠️  No pages found in the wiki. Double-check wiki name and project/org." -ForegroundColor Yellow
    } else {
        Write-Host "`n✅ Pages returned:`n"
        $response.value | ForEach-Object { Write-Host $_.path }
    }
} catch {
    Write-Host "`n❌ API call failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
