1  # Config - Replace with your real values
2  $adoOrg     = "your-org"         # e.g., contoso
3  $adoProject = "your-project"     # e.g., DevOpsTeam
4  $wikiName   = "your-wiki-name"   # e.g., ProjectWiki
5  $adoPat     = "your-ado-pat"     # e.g., a long token string
6
7  # Auth header
8  $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$adoPat"))
9  $authHeader = @{
10     Authorization = "Basic $base64Auth"
11 }
12
13 # Build URL
14 $url = "https://dev.azure.com/$adoOrg/$adoProject/_apis/wiki/wikis/$wikiName/pages?api-version=6.0&recursionLevel=Full"
15
16 Write-Host "`n🔎 Requesting pages from:"
17 Write-Host $url -ForegroundColor Cyan
18
19 try {
20     $response = Invoke-RestMethod -Uri $url -Headers $authHeader -ErrorAction Stop
21
22     if ($response.value.Count -eq 0) {
23         Write-Host "`n⚠️  No pages found in the wiki." -ForegroundColor Yellow
24     }
25     else {
26         Write-Host "`n✅ Pages found:`n" -ForegroundColor Green
27         $response.value | ForEach-Object { Write-Host $_.path }
28     }
29 }
30 catch {
31     Write-Host "`n❌ API request failed:" -ForegroundColor Red
32     Write-Host $_.Exception.Message -ForegroundColor Red
33 }
