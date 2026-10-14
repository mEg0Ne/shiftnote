# シフトノート（ShiftNote）

アルバイトの日程と勤務時間を管理する Flutter アプリ。
カレンダーでシフトを登録・閲覧し、月ごとの勤務時間を集計します。

## 機能
- ユーザー登録／ログイン／ログアウト（パスワードはソルト付き SHA-256 で保存）
- シフトの登録・編集・削除（開始／終了時刻、休憩、メモ、繰り返し登録、夜勤対応、時間重複チェック）
- カレンダー表示、出勤済みへの切替
- 月間集計（合計実働時間・勤務日数・月別グラフ）
- マイページ（参照・プロフィール更新・パスワード変更）

## 構成
```
lib/
  main.dart              起動・Provider・全体のエラー捕捉
  app/                   テーマ、AuthGate（ログイン状態で画面を切替）
  core/                  例外、Result、入力検証、整形、パスワードハッシュ
  models/                User, Shift, 集計用クラス
  data/                  AppDatabase(SQLite), UserRepository, ShiftRepository, SessionStore
  providers/             AuthProvider, ShiftProvider（状態管理）
  screens/               S01〜S09 の各画面
  widgets/               共通部品、棒グラフ
test/unit_test.dart      単体テスト
docs/                    シーケンス図・クラス図
```
画面ID対応：S01 ログイン／S02 登録／S03 ホーム／S04 シフト登録・編集／S05 シフト詳細／S06 月間集計／S07 マイページ／S08 プロフィール編集／S09 パスワード変更

## 動作環境
- Flutter 3.22 以上（動作確認に使う想定バージョン：3.24.5）
- Android / iOS（SQLite に sqflite を使うため、Web・デスクトップは非対応）

## 実行・ビルド手順
```bash
# 1. プロジェクト直下で、Android 用ファイルを生成（lib/ と pubspec.yaml は上書きされません）
flutter create --platforms=android --project-name shiftnote --org com.example .
rm -f test/widget_test.dart      # 自動生成されるサンプルテストは不要
# 2. 依存パッケージ取得、解析、テスト
flutter pub get
flutter analyze
flutter test
# 3. 実機・エミュレータで実行
flutter run
# 4. リリース用 APK を作成
flutter build apk --release
#   → build/app/outputs/flutter-apk/app-release.apk
```

## GitHub Actions で APK を作る場合
このフォルダを GitHub のリポジトリに push すると、`.github/workflows/build-apk.yml` が
自動で APK をビルドします。Actions の実行結果ページの Artifacts（shiftnote-apk）から
`app-release.apk` をダウンロードできます。
