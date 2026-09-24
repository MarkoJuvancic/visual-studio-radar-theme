param(
    [Parameter(Mandatory=$true)]
    [string]$VsixPath
)

$ErrorActionPreference = 'Stop'
$themeGuid = '9dbab5c6-1554-5d9a-b69d-8cbfb045d22b'

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $VsixPath))
try {
    $pkgdefs = @($zip.Entries | Where-Object { $_.FullName -like '*.pkgdef' })
    Write-Host "PKGDEF entries found: $($pkgdefs.Count)"
    foreach ($entry in $pkgdefs) {
        Write-Host "  - $($entry.FullName)"
    }

    if ($pkgdefs.Count -lt 2) {
        throw "Expected at least two .pkgdef entries: one for the VSPackage and one for Radar theme colors."
    }

    $themeFound = $false
    foreach ($entry in $pkgdefs) {
        $reader = New-Object System.IO.StreamReader($entry.Open())
        try {
            $text = $reader.ReadToEnd()
            if ($text -match [regex]::Escape("`$RootKey`$\Themes\{$themeGuid}")) {
                Write-Host "Radar theme registration found in: $($entry.FullName)"
                $themeFound = $true
                break
            }
        }
        finally {
            $reader.Dispose()
        }
    }

    if (-not $themeFound) {
        throw "Radar theme registry key was NOT found in the built VSIX. Do not install this package."
    }

    Write-Host "VSIX verification PASSED." -ForegroundColor Green
}
finally {
    $zip.Dispose()
}
