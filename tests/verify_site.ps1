param(
    [Parameter(Mandatory = $true)]
    [string]$PublicDir
)

$requiredFiles = @(
    'index.html',
    'contact/index.html',
    'merken-en-verdelers/index.html',
    'driveshop/index.html',
    'bikeshop/index.html'
)

$missingFiles = @()

foreach ($relativePath in $requiredFiles) {
    $fullPath = Join-Path $PublicDir $relativePath
    if (-not (Test-Path $fullPath)) {
        $missingFiles += $relativePath
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Error ('Missing generated files: ' + ($missingFiles -join ', '))
    exit 1
}

Write-Host 'All required files exist.'
