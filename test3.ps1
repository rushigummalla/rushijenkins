# ========== CONFIG ==========
$adoOrg = "your-org"
$adoProject = "your-project"
$wikiName = "your-wiki"
$adoPat = "your-azure-pat"
$exportDir = "wiki-export"

# ========== AUTH ==========
$authHeader = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$adoPat"))
}

# ========== UTILITY ==========
function Save-Content {
    param ($path, $content)
    $dir = Split-Path $path
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Set-Content -Path $path -Value $content
}

function Convert-MarkdownToHtml {
    param ($mdFile)
    $htmlFile = $mdFile -replace "\.md$", ".html"
    pandoc $mdFile -f markdown -t html -o $htmlFile
    return $htmlFile
}

function Extract-Images {
    param ($markdown)
    $pattern = '!\[.*?\]\((.*?)\)'
    $matches = Select-String -InputObject $markdown -Pattern $pattern -AllMatches
    return $matches.Matches | ForEach-Object { $_.Groups[1].Value }
}

function Download-Image {
    param ($imgUrl, $outputPath)
    try {
        Invoke-WebRequest -Uri $imgUrl -Headers $authHeader -OutFile $outputPath -ErrorAction Stop
    } catch {
        Write-Warning "Failed to download image: $imgUrl"
    }
}

# ========== MAIN ==========
Write-Host "Exporting Azure DevOps Wiki to $exportDir"
New-Item -ItemType Directory -Path $exportDir -Force | Out-Null

# Step 1: Fetch all wiki pages
$pageListUrl = "https://dev.azure.com/$adoOrg/$adoProject/_apis/wiki/wikis/$wikiName/pages?api-version=6.0&recursionLevel=Full"
$pages = (Invoke-RestMethod -Uri $pageListUrl -Headers $authHeader).value

$index = @()

# Step 2: Process each page
foreach ($page in $pages) {
    $pagePath = $page.path.TrimStart("/")
    $pageName = $pagePath.Split("/")[-1]
    $normalizedPath = $pagePath -replace "/", "\"
    $localMdPath = Join-Path $exportDir "$normalizedPath.md"
    $localHtmlPath = $localMdPath -replace "\.md$", ".html"

    Write-Host "Downloading: $pagePath"

    # Step 2a: Get page content
    $pageContentUrl = "https://dev.azure.com/$adoOrg/$adoProject/_apis/wiki/wikis/$wikiName/pages/$($page.id)?includeContent=true&api-version=6.0"
    $content = (Invoke-RestMethod -Uri $pageContentUrl -Headers $authHeader).content

    # Step 2b: Save markdown
    Save-Content -path $localMdPath -content $content

    # Step 2c: Download images
    $imageUrls = Extract-Images -markdown $content
    $imgFolder = Join-Path (Split-Path $localMdPath) "images"
    foreach ($imgUrl in $imageUrls) {
        if ($imgUrl -match "^https://dev\.azure\.com") {
            $imgFile = [System.IO.Path]::GetFileName($imgUrl)
            $imgPath = Join-Path $imgFolder $imgFile
            Download-Image -imgUrl $imgUrl -outputPath $imgPath
        }
    }

    # Step 2d: Convert to HTML
    Convert-MarkdownToHtml -mdFile $localMdPath | Out-Null

    # Step 2e: Determine parent path
    if ($pagePath -like "*/*") {
        $parent = $pagePath -replace "/[^/]+$", ""
    } else {
        $parent = ""
    }

    # Step 2f: Track in index
    $index += [PSCustomObject]@{
        path       = $pagePath
        name       = $pageName
        markdown   = $localMdPath
        html       = $localHtmlPath
        images     = $imageUrls
        parentPath = $parent
    }
}

# Step 3: Save metadata index
$indexPath = Join-Path $exportDir "index.json"
$index | ConvertTo-Json -Depth 10 | Set-Content -Path $indexPath

Write-Host "`n✅ Export complete! All pages saved in: $exportDir"
