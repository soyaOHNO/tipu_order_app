# プロジェクト構成と前提ルール (Project Structure & Rules)

このドキュメントは、「町屋やきにく密陽家（みらんちぷ）」専用の発注管理・予約計算アプリ（Flutter/Dart Webアプリケーション）の全体構造と、開発における**絶対厳守のルール**、各ファイルの詳細仕様、およびデプロイ手法を網羅的にまとめたものです。AIや新規開発者がプロジェクトを触る際の共通認識（システムアーキテクチャの青写真）として機能します。

---

## ⚠️ 【重要】開発における絶対ルール (Core Principles)

1. **店舗名**: 「町屋やきにく密陽家」は「みらんちぷ」と読む。
2. **Firebaseデータ最優先（上書き厳禁）**:
   すでに現場（店舗）での運用が始まっており、発注品目や料理マスタなどのデータは現場スタッフの手によってFirestore上に追加・更新されている。**コード側の初期データ（モックデータ）でFirestore上の本番データを絶対に上書き・初期化してはならない。** マスタ操作のロジックを変更する際は、既存データを破壊しないことを最優先とし、必ずFirestore側のデータをマスターとする。
3. **Toreta連携の現状**:
   Firebase Cloud Functions上にPythonベースの専用APIをデプロイし、Toretaからの予約CSV取得・JSON変換ロジックが完成済み。食べログや一休等の「表記ゆれ」や「席のみ」予約を完璧にクレンジングするパーサーを搭載しており、Flutter側はAPIキー認証を用いて安全に整形済みのJSONデータを取得する仕様となっている。これにより、予約人数とコースに応じた必要食材の自動計算ロジックが完全に機能する状態である。
4. **Webキャッシュ問題の回避**:
   店舗端末（iPad等）でのWebアプリとして運用しているため、PWAやブラウザのキャッシュによって古いバージョンのアプリが開き続ける問題がある。これを回避するため、独自のバージョンチェックと強制リロード機構（後述）を実装しており、この機構を無効化してはならない。

---

## 🚀 自動デプロイとバージョン管理 (CI/CD & Versioning)

本プロジェクトは、安全かつ確実なアップデートを店舗端末に行き渡らせるための独自のデプロイパイプラインを持っています。

### 1. `deploy.ps1` (PowerShellデプロイスクリプト)
手動での `flutter build web` 等は行わず、必ずプロジェクトルートにある `deploy.ps1` を実行してデプロイを行います。このスクリプトは以下の工程を全自動で処理します。
* **バージョンの自動カウントアップ**: `pubspec.yaml` の `version: X.Y.Z+B` を読み取り、PatchバージョンとBuild番号を自動でインクリメント（+1）します。
* **`app_config.dart` の自動生成**: インクリメントした新しいバージョン文字列（例: `1.0.18+19`）を埋め込んだ `lib/config/app_config.dart` を自動生成し、Flutterアプリ側から静的な定数としてバージョンを参照できるようにします（プラグイン非依存で確実な値を取得するため）。
* **Flutter Webビルド**: `.env` を適用した上で `flutter build web --release` を実行します。
* **Firebase Hostingへのデプロイ**: `firebase deploy --only hosting` を実行します。
* **Firestoreのバージョン更新**: Node.jsスクリプト (`update_version.js`) を呼び出し、Firestoreの `app_info/version` ドキュメント内の `latest_version` を新バージョンで上書きします。
* **Gitへの自動コミット＆プッシュ**: デプロイ成功後、`release: version X.Y.Z+B` というメッセージで自動的にコミットし、`main` ブランチへプッシュします。

### 2. キャッシュクリア・強制リロード機構 (`lib/utils/version_check.dart`)
アプリの起動時（`main.dart`）の最優先処理として、`checkAppVersionAndReload()` が呼び出されます。
* `app_config.dart` に埋め込まれた自身のバージョンと、Firestore (`app_info/version`) に保存されている最新バージョンを比較します。
* Firestore側のバージョンが新しい場合、古いキャッシュを見ていると判断し、`html.window.location.reload()` を発火させてブラウザを強制リロードさせます。これにより、現場のiPadが常に最新のアプリをロードすることが保証されます。

---

## 🔌 Toreta連携 API仕様 (API Reference)

FlutterアプリからToretaの予約データを取得するための自作プライベートAPI（Google Cloud Functions）の仕様です。

* **エンドポイントURL**: `https://us-central1-tipu-order.cloudfunctions.net/get_reservations`
* **HTTPメソッド**: `GET`
* **必須ヘッダー**:
  * `X-API-KEY`: プロジェクト内の `.env` に `SECRET_API_KEY` として保存している値。
* **クエリパラメータ**:
  * `date`: 取得対象の日付。形式は `YYYY-MM-DD`（例: `?date=2026-08-04`）
* **レスポンス形式の一例 (JSON配列)**:
  ```json
  [
    {
      "start_time": "18:00",
      "end_time": "20:00",
      "table_id": "V1",
      "people": 2,
      "course": "赤身天国コース", 
      "note": null
    },
    {
      "start_time": "19:00",
      "end_time": "21:00",
      "table_id": "03",
      "people": 2,
      "course": null, 
      "note": "媒体名：tabelog\nコース：お席のみのご予約"
    }
  ]
  ```
  * ※Python側のパーサーによりコース名は完全一致のマスター名称に正規化済み。「席のみ」やコース不明の場合は `course: null` となるため、Flutter側での文字列解析は不要。*

---

## ⚙️ システム全体仕様 & 重要アルゴリズム (System Architecture & Core Logic)

### 1. 営業日管理（朝6時基準）
深夜営業に対応するため、**朝6時を境に日付を切り替える**ロジックを採用している。
* 朝6時前である場合：前日の日付を当日の営業日とする。
* 朝6時以降である場合：当日の日付を営業日とする。
* **履歴移行と自動リセット**: アプリの起動や復帰時に、Firestore上に保存されている前回の稼働日（`business_date`）と現在の計算上の営業日を比較する。日付が変わっていることを検知した場合、前日の発注データを履歴コレクション（`order_history` および `hall_order_history`）に自動転送し、当日の発注数やチェック状態を初期目標値へ自動リセット（クリア）する。

### 2. Firestoreリアルタイム同期とオフラインキャッシュ
* 発注状況（`working_orders/current` および `working_hall_orders/current`）は `snapshots()` を用いてStream購読している。複数端末で同時に発注数を増減させたりチェックを入れたりした場合でも、リアルタイムに画面が同期される。
* `persistenceEnabled: true` を設定してFirestoreのローカルキャッシュを有効化しており、店舗の地下等で一時的に電波が悪くなった場合でも入力データが失われないよう強力なオフライン対応を行っている。

### 3. Toreta予約に基づく必要食材量自動計算
翌日の予約人数とコース構成に基づき、厨房の必要食材の自動計算を行う。
* **計算タイプ (`calcType`)**:
  * `proportion` (人数比例・増減型): 3名基準の標準必要量に対して、人数比率（`1.0 + (人数 - 3) * 0.2`）を適用する。テーブルごとに固定量にするフラグが有効な場合は比例計算を行わない。
  * `per_person` (人数＝個数型): 単純に人数に比例して必要数を計算する。
  * `step` (段階・しきい値型): 人数のレンジ（段階）によって個数が段階的に変わる。
  * `per_table` (テーブル固定型): 人数に関係なく、1テーブルあたり一律で一定量を算出する。
* **特例ルール (`specialRule`)**:
  * `sanchu_2p`: サンチュ専用。通常は人数と同パック数だが、2名予約の場合のみ「4枚（パック数換算で少なめ）」とする特例。
  * `reimen_step`: 盛岡冷麺専用。3名基準（2名=0.5パック、3-4名=1パック、5名=1.5パック、6-7名=2パック）のしきい値計算。
  * `kuppa_step`: クッパ専用。2-4名=1、それ以外=2のしきい値計算。
* **歩留まり換算**: 算出された必要総量に対し、食材マスタに登録されている単位あたりの歩留まり（`yieldPerUnit`）で除算し、最終的な発注単位（パック、箱など）に切り上げ（`ceilToDouble()`）て算出する。

---

## 🏬 ホール発注管理機能 (Hall Order Management)

キッチン・裏方の発注システムとは完全に切り離された、ホール独自の在庫・発注管理システム。現場のペーパー運用をシステム化し、自動計算と手動調整を両立している。

### 1. データモデルとマスタ (`HallItem`)
* **完全隔離の原則**: キッチン側のデータ構造(`Item`, `OrderItem`)とは完全に独立した `HallItem` モデル（`lib/models/hall_item.dart`）を使用。
* **相互作用（`sameId`）**: 冷蔵庫①（メイン）と冷蔵庫③（ストック）のように、保管場所が分かれている同一商品を連動させる仕組み。`sameId` で紐付けることで、タブ①（在庫入力）ではストック数のみを入力させ、タブ②（発注管理）では合算して発注数を自動計算する。
* **isSupply フラグ**: 在庫を数えるドリンク類か、チェックボックスのみで管理する補充・消耗品（トイレットペーパー等）かを判別。

### 2. 独自の自動計算ルール
* **基本ロジック**: `(目標在庫数) - (現在庫数[開栓+未開栓+ストック]) = 基準発注数`
* **特例ロジック（生マッコリ等）**: `manualAdjustment` や閾値を設け、「残り2本以下になったら、8本（ケース）単位で切り下げて発注」といった独自のルールをマスタの `memo` 等と連携して処理する設計。

### 3. 画面構成 (3タブ + 1確認画面)
* **タブ①: 在庫入力 (`InventoryInputTab`)**: アルバイト向け。冷蔵庫を開け、ひたすら「開栓」「未開栓」「ストック」の数を入力する専用画面。目標数（MAX値）を初期値とし、「減った分をマイナスする」UIを採用し入力負荷を軽減。
* **タブ②: 発注数管理 (`OrderManagementTab`)**: チーフ・社員向け。タブ①の入力から自動計算された発注数を確認し、必要に応じて手動調整（`manualAdjustment`）を行う。
* **タブ③: 補充 (`ReplenishmentTab`)**: 消耗品のチェック画面。
* **発注確認画面 (`hall_confirm_page.dart`)**: 最終的な発注リスト。アイテム属性から「業者へ発注」「バーに報告」「キッチンに報告」の3セクションに自動分類し、編集不可（Read-only）で表示。

### 4. リアルタイム同期と履歴保存 (★未完了・実装予定)
* **リアルタイム同期**: `working_hall_orders` コレクションを用い、複数スタッフ間の入力をリアルタイム同期する（キッチン側と同等の仕組み）。
* **履歴保存（朝6時リセット）**: 朝6時を境に、`working_hall_orders` の状態を抽出し `hall_order_history/{YYYY-MM-DD}` へ転送・保存するロジック（`lib/data/hall_order_data.dart` に実装予定）。
* **履歴閲覧画面**: `previous_order_page.dart` を拡張（または別画面作成）し、ホール履歴も閲覧可能にする。

---

## 🖨️ 伝票発券機（キッチンプリンタ）との連携

現場の iPad から、ローカルネットワーク経由で EPSON TM-m30（ICC-00031）へ直接印刷するための仕組み。iOS(Safari) の強力な Web 制約を回避するための特殊な実装を行っている。

### 1. 通信仕様
* **対象プリンタ**: EPSON TM-m30 (ICC-00031 / 前方排出・80mm幅)
* **IPアドレス**: 192.168.32.202 (または 203)
* **プロトコル**: ePOS-Print XML (HTTP POST通信)
* **エンドポイント**: `http://192.168.32.202/cgi-bin/epos/dispacher?devid=local_printer&timeout=10000`

### 2. iOS(Safari) 制限回避ロジック
Flutter Web からローカル IP (http://...) への直接 POST 通信や `url_launcher` によるカスタム URL スキーム起動は、iOS/Safari のセキュリティ制限（CORS、Mixed Content、サイレントエラー）に阻まれる。これを回避するため、以下の連携を採用。
1. **Flutter アプリ**: 印刷データを構成し、SOAP (ePOS-Print XML) 形式の完璧なテキストを生成。
2. **クリップボード転送**: 生成した XML をクリップボードにコピー（`Clipboard.setData`）。
3. **ショートカット起動**: Web 標準の `html.window.location.href` を用いて、iPad 上の iOS ショートカットアプリ (`shortcuts://run-shortcut?name=PrintOrder`) を確実に起動。
4. **iOS ショートカット (`PrintOrder`)**: クリップボードの中身（XML）を取得し、プリンタの IP アドレスに対して HTTP POST リクエストを送信し、印刷を実行。

---

## 🔮 将来の展望: NECモバイルPOS連携による「予測発注」

現在の Toreta 連携（予約人数ベース）をさらに進化させ、POS の過去の売上データを活用した究極の「予測発注システム」を構築する構想。

### 1. 狙いと価値
* 単なる「現在の在庫管理」から「未来の消費予測」への転換。
* ベテランの「勘」への依存（属人化）を排除し、食品ロス・品切れを最小化する。

### 2. 実現に向けたアプローチ (API 連携)
* **対象システム**: NECモバイルPOS
* **手法**: 既存の Toreta 同様、Python (Cloud Functions) を中継サーバーとし、NECモバイルPOS の標準外部連携 API をコールして売上・商品データを取得・解析する。
* **必須アクション**: 契約者（オーナー）経由で NEC サポート（または代理店）へ「外部システム連携用の API 仕様書と API キー（アクセストークン）」の発行を申請する必要がある。アクティベーション情報周辺にある「企業コード（テナントID）」や「店舗コード」も利用する可能性が高い。


---

## 📁 ディレクトリ構造 (Directory Tree)

```text
tipu_order_app/
├── deploy.ps1                    # 自動デプロイ用PowerShellスクリプト
├── update_version.js             # Firestoreのバージョン更新用Node.jsスクリプト
├── serviceAccountKey.json        # Firebase Admin SDK用サービスアカウントキー
├── lib/
│   ├── config/
│   │   └── app_config.dart       # deploy.ps1により自動生成されるバージョン定義ファイル
│   ├── data/
│   │   ├── course_data.dart      # コースデータ通信
│   │   ├── dish_data.dart        # 料理データ通信
│   │   ├── hall_item_data.dart   # ホール品マスタ通信
│   │   ├── hall_order_data.dart  # ホール発注・履歴移行通信
│   │   ├── item_data.dart        # 厨房品マスタ通信
│   │   └── reservation_data.dart # Toreta API HTTP通信
│   ├── models/
│   │   ├── course_recipe.dart
│   │   ├── dish.dart
│   │   ├── hall_item.dart
│   │   ├── item.dart
│   │   ├── order_item.dart
│   │   └── reservation.dart
│   ├── pages/
│   │   ├── board_page.dart                 # ホワイトボード転記用画面
│   │   ├── chief_page.dart                 # チーフ・仕入先別画面
│   │   ├── course_edit_page.dart           # コースマスタ編集
│   │   ├── dish_edit_page.dart             # 料理マスタ編集
│   │   ├── hall_confirm_page.dart          # ホール発注確認
│   │   ├── hall_master_edit_page.dart      # ホール品マスタ編集
│   │   ├── hall_order_page.dart            # ホール発注メイン
│   │   ├── hall_previous_order_page.dart   # ホール発注履歴
│   │   ├── master_edit_page.dart           # 厨房品マスタ編集
│   │   ├── memo_page.dart                  # ローカルメモ
│   │   ├── order_home_page.dart            # 厨房発注メイン
│   │   ├── previous_order_page.dart        # 厨房発注履歴
│   │   └── reservation_page.dart           # 予約確認・印刷用
│   ├── utils/
│   │   ├── date_utils.dart       # 営業日（6時切り替え）計算
│   │   └── version_check.dart    # Firestoreを利用したアプリ更新検知・リロード処理
│   ├── firebase_options.dart
│   └── main.dart
```

---

## 📂 フォルダ・ファイル詳細仕様

### 🔧 ルート直下スクリプト群
* **deploy.ps1**: ビルド、バージョン付与、デプロイ、Firestore更新、Gitコミット＆プッシュを一元化するデプロイパイプラインの心臓部。
* **update_version.js**: `firebase-admin` を用いてFirestoreの `app_info/version` を安全に書き換えるためのNode.jsスクリプト。`deploy.ps1` から呼び出される。
* **serviceAccountKey.json**: 上記 `update_version.js` がFirestoreへ管理者権限で書き込みを行うための認証キー。

### 📦 lib 直下 (エントリーポイント)
* **main.dart**:
  * アプリ起動のエントリーポイント。`dotenv.load` による環境変数読み込み、Firebase初期化、および最も重要な **`checkAppVersionAndReload()` の実行** を担う。
  * オフラインキャッシュの設定(`persistenceEnabled: true`)を行い、スプラッシュ画面にてFirestoreから全マスタデータ（発注品・ホール・料理・コース）を非同期ロードする。
  * `TopMenuPage` (UI構成) はグリッドビュー形式で各種ページへのランチャーを提供し、画面下部のフッターには `AppConfig.version` を静的に表示する。
* **firebase_options.dart**: Firebase CLIによって自動生成されたプラットフォームごとの接続設定。

### ⚙️ lib/config (自動生成設定)
* **app_config.dart**: `deploy.ps1` によって上書き生成されるファイル。クラス `AppConfig` に静的定数 `version` を保持し、アプリ全体の「現在のバージョン」の絶対的な情報源となる。

### 📂 lib/models (データモデル定義)
* **item.dart**: 厨房・裏方発注品の定義モデル。`kitchen_minimum`(キッチンでの最低数), `back_minimum`(裏での最低数) の2重管理構造を持つ。発注担当 (`OrderType`) や論理削除フラグ (`alive`) を持つ。
* **order_item.dart**: 実際の発注操作における作業状態を表すモデル。数量(`quantity`)と在庫ありフラグ(`inStock`)を保持。`.0` を自動で切り捨てる `toDisplayString()` 拡張メソッドを提供。
* **hall_item.dart**: ドリンク・ホール補充品の定義・計算モデル。`sameId` による複数箇所の在庫連動計算機能を持ち、目標数(`targetStock`) と 現在庫(`stock`)、発注閾値(`orderThreshold`) から不足数を自動計算して発注単位(`orderUnit`) に切り上げる `calculateTotalOrderAmount` メソッドを持つ。
* **dish.dart**: 料理定義モデル。計算タイプ(`calcType`)、特例ルール(`specialRule`)、および必要な食材リスト(`requiredItems` - `DishItemRequirement`)を紐付けて管理する。
* **course_recipe.dart**: コース定義モデル。現場呼称(`courseName`)とToreta検索用キーワード(`toretaKeyword`)を持ち、構成する料理IDリストを管理する。
* **reservation.dart**: Toreta APIからパースされた予約情報のモデル。卓番、人数、コース名、備考を保持。

### 📂 lib/data (Firestore・外部通信連携)
* **item_data.dart**: 厨房マスタの通信。過去のデータ構造を新構造に移行しながらロードする `loadItemMaster()` を提供。
* **hall_item_data.dart**: ホール商品マスタの通信。初回起動時の初期データ投入とカテゴリ仕分けを担う。
* **hall_order_data.dart**: ホール発注の作業中データ管理と、日付跨ぎ時の `checkAndTransferHallHistory()`（履歴へのエスケープ処理）を担う。
* **dish_data.dart** / **course_data.dart**: 料理・コースマスタの読み書き。
* **reservation_data.dart**: `.env` の `SECRET_API_KEY` を利用した Google Cloud Functions へのセキュアな HTTP GETリクエストを行い、予約配列を取得する。

### 📂 lib/utils (共通ユーティリティ)
* **date_utils.dart**: 朝6時を境界として営業日を判定する `getBusinessDate()` を提供。アプリ全体の日付判定の基準となる。
* **version_check.dart**: Firestoreの `app_info/version` を読みに行き、`AppConfig.version` と不一致の場合に `html.window.location.reload()` を発火させるWebアプリキャッシュ対策のコアロジック。

### 📂 lib/pages (画面定義)

#### 🍳 厨房・裏方発注フロー
* **order_home_page.dart**: 厨房・裏方用のメイン発注入力画面。「キッチン側」「裏側」の2モードを切り替え、Firestore `working_orders` とリアルタイム同期。翌日予約に基づく必要食材の自動計算（`+予約分: X`）や、月曜定休のための「日曜日警告バナー」を表示。400msのデバウンス処理による安全なFirestore更新を実装。
* **board_page.dart**: アルバイトスタッフ向けの「ホワイトボード書き写し用」シンプルリスト画面。
* **chief_page.dart**: チーフおよび仕入先別の確認画面。仕入先名でグループ化＆ソートし、オーナー（とも兄さん）宛の発注を分離して表示。
* **previous_order_page.dart**: `order_history` を参照し、年月日別のツリー構造プルダウンから過去の厨房発注内容を閲覧できる画面。
* **memo_page.dart**: `SharedPreferences` を使用した端末ローカルのテキストメモ画面。

#### 🍷 ホール発注フロー
* **hall_order_page.dart**: ホールスタッフ向け発注メイン画面。「在庫入力（開栓・未開栓）」「発注数管理（自動計算＋手動調整）」「補充（消耗品チェック）」の3タブで構成。
* **hall_confirm_page.dart**: ホール発注の最終確認画面。抽出された発注アイテムを、名前やカテゴリに含まれるキーワードから自動的に「キッチンに報告」「バーに報告」「発注リスト」の3セクションに分類して表示。
* **hall_master_edit_page.dart**: ホール商品マスタの追加・編集画面。
* **hall_previous_order_page.dart**: `hall_order_history` を参照するホール用の履歴画面。`previous_order_page.dart` と同様の年月日のツリー構造UIを持ち、特定日の履歴データを「キッチンに報告」「バーに報告」「発注リスト」の3セクションに再分類して表示する。

#### 📋 マスタ編集・設定フロー
* **master_edit_page.dart**: 厨房品マスタの編集。論理削除済みデータの復元アシスト機能を搭載。
* **dish_edit_page.dart**: 料理マスタの編集。計算タイプや歩留まり、必要食材の細かなレート設定を行う。
* **course_edit_page.dart**: コースレシピマスタの編集。Toretaキーワードとのマッピングを行う。

#### 📅 予約状況確認フロー
* **reservation_page.dart**: Toreta予約情報のマトリクス表示画面。時間軸と卓番をクロスさせたUIで予約カードを表示。ハンディ伝票印刷用に、予約内容から「プレート」等のキーワードを抽出・強調し、コース名を省略形（例: 赤身天国→赤天）に整形したテキストをクリップボードにコピーする機能を持つ。