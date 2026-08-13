# 文字化け防止
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🚀 みらんちぷ発注アプリ 自動デプロイ開始" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$pubspecPath = ".\pubspec.yaml"
$content = Get-Content $pubspecPath -Raw

# 1. バージョンの自動カウントアップ (例: 1.0.0 -> 1.0.1+1)
if ($content -match '(?m)^version:\s*([0-9]+)\.([0-9]+)\.([0-9]+)(?:\+([0-9]+))?') {
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $patch = [int]$matches[3]
    $build = if ($matches[4]) { [int]$matches[4] } else { 0 }

    $newPatch = $patch + 1
    $newBuild = $build + 1

    $oldVersionLine = $matches[0]
    $newVersion = "$major.$minor.$newPatch+$newBuild"
    $newVersionLine = "version: $newVersion"

    $content = $content.Replace($oldVersionLine, $newVersionLine)
    
    $utf8NoBom = New-Object System.Text.UTF8Encoding $False
    [System.IO.File]::WriteAllText((Resolve-Path $pubspecPath), $content, $utf8NoBom)

    Write-Host "📦 バージョンを自動更新しました: [ $oldVersionLine ] -> [ $newVersionLine ]" -ForegroundColor Green
    
    $version = $newVersion

    
    # =========================================================
    # ★追加（1.5）: Dart用バージョンファイルを自動生成する
    # =========================================================
    Write-Host "`n📝 Dart用バージョンファイルを生成しています..." -ForegroundColor Yellow
    $configDir = ".\lib\config"
    if (-Not (Test-Path $configDir)) { New-Item -ItemType Directory -Force -Path $configDir | Out-Null }
    
    $dartVersionFile = "$configDir\app_config.dart"
    $dartContent = "class AppConfig {`n  static const String version = '$newVersion';`n}"
    
    [System.IO.File]::WriteAllText($dartVersionFile, $dartContent, $utf8NoBom)
    Write-Host "✅ app_config.dart を生成しました。" -ForegroundColor Green
    # =========================================================
} else {
    Write-Host "❌ pubspec.yaml からバージョンを取得できませんでした。" -ForegroundColor Red
    exit
}

# 2. Flutter Webのビルド
Write-Host "`n🔨 Flutter Webをビルドしています..." -ForegroundColor Yellow
flutter build web --release --dart-define-from-file=.env
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ビルドに失敗しました。" -ForegroundColor Red
    exit
}

# 3. Firebase Hostingへデプロイ
Write-Host "`n☁️ Firebase Hostingへデプロイしています..." -ForegroundColor Yellow
firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ デプロイに失敗しました。" -ForegroundColor Red
    exit
}

# 4. Firestoreのバージョン情報を更新
Write-Host "`n📝 Firestoreのバージョン情報を更新しています..." -ForegroundColor Yellow
node update_version.js $version
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ バージョン情報の更新に失敗しました。" -ForegroundColor Red
    exit
}

# 5. Gitへの自動コミット＆プッシュ
Write-Host "`n🌿 Gitリポジトリへ変更を反映しています..." -ForegroundColor Yellow
git add .
# 変更がある場合のみコミットとプッシュを実行する安全策
$gitStatus = git status --porcelain
if ($gitStatus) {
    # コミットメッセージに自動生成したバージョン番号を使う
    git commit -m "release: version $version"
    # ※もしメインブランチ名が master の場合は、下の main を master に変えてください
    git push origin main
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Gitプッシュに失敗しました。認証エラー等がないか手動で確認してください。" -ForegroundColor Red
        exit
    }
    Write-Host "✅ Gitへのプッシュが完了しました！" -ForegroundColor Green
} else {
    Write-Host "⚠️ コミットする新しい変更がありませんでした。" -ForegroundColor DarkYellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✨🎉 全てのデプロイ作業が完了しました！ 🎉✨" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan