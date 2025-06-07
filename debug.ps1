$adoOrg = "your-org"
$adoProject = "your-project"
$wikiName = "your-wiki"
$adoPat = "your-azure-pat"

$authHeader = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$adoPat"))
}

$url = "https://dev.azure.com/$adoOrg/$adoProject/_apis/wiki/wikis/$wikiName/pages?api-version=6.0&recursionLevel=Full"

$response = Invoke-RestMethod -Uri $url -Headers $authHeader
$response.value | ForEach-Object { $_.path }
