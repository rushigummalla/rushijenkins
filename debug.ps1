# ======== CONFIGURATION - REPLACE THESE ========
$adoOrg     = "your-org"         # e.g., contoso
$adoProject = "your-project"     # e.g., DevOpsTeam
$wikiName   = "your-wiki-name"   # e.g., ProjectWiki
$adoPat     = "your-ado-pat"     # e.g., a long token string
# ===============================================

# Create the auth header
$base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$adoPat"))
$authHeader = @{
    Authorization = "Basic $base64Auth"
}

# Build the URL
$url = "https://dev.azure.com/$adoOrg/$adoProject/_apis/wiki/wikis/$wikiName/pages?api-version=6.0&recursionLevel=Full"

Write-Host "`n🔎 Requesting pages from:"
Write-Host $url -ForegroundColor Cyan

# Make the request
try {
    $response = Invoke-RestMethod -Uri $url -Headers $authHeader -ErrorAction Stop

    if ($response.value.Count -eq 0) {
        Write-Host "`n⚠️  No pages found in the wiki." -ForegroundColor Yellow
    }
    else {
        Write-Host "`n✅ Pages found:`n" -ForegroundColor Green
        $response.value | ForEach-Object { Write-Host $_.path }
    }
}
catch {
    Write-Host "`n❌ API request failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
