# プロジェクト構成と前提ルール (Project Structure & Rules)

このドキュメントは、「町屋やきにく密陽家（みらんちぷ）」専用の発注管理・予約計算アプリ（Flutter/Dart）の全体構造と、開発における**絶対厳守のルール**、各ファイルの詳細仕様をまとめたものです。AIや新規開発者がプロジェクトを触る際の共通認識として機能します。

---

## ⚠️ 【重要】開発における絶対ルール (Core Principles)

1. **店舗名**: 「町屋やきにく密陽家」は「みらんちぷ」と読む。
2. **Firebaseデータ最優先（上書き厳禁）**:
   すでに現場（店舗）での運用が始まっており、発注品目や料理マスタなどのデータは現場スタッフの手によってFirestore上に追加・更新されている。**コード側の初期データ（モックデータ）でFirestore上の本番データを絶対に上書き・初期化してはならない。** マスタ操作のロジックを変更する際は、既存データを破壊しないことを最優先とする。
3. **Toreta連携の現状**:
   Firebase Cloud Functions上にPythonベース of 専用APIをデプロイし、Toretaからの予約CSV取得・JSON変換ロジックが完成済み。食べログや一休等の「表記ゆれ」や「席のみ」予約を完璧にクレンジングするパーサーを搭載しており、Flutter側はAPIキー認証を用いて安全に整形済みのJSONデータを取得する仕様となっている。これにより、予約人数とコースに応じた必要食材の自動計算ロジックが完全に機能する状態である。

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
  *※Python側のパーサーによりコース名は完全一致のマスター名称に正規化済み。「席のみ」やコース不明の場合は `course: null` となるため、Flutter側での文字列解析は不要。*

---

## ⚙️ システム全体仕様 & 重要アルゴリズム (System Architecture & Core Logic)

### 1. 営業日管理（朝6時基準）
深夜営業に対応するため、**朝6時を境に日付を切り替える**ロジックを採用している。
* 朝6時前である場合：前日の日付を当日の営業日とする。
* 朝6時以降である場合：当日の日付を営業日とする。
* **履歴移行と自動リセット**: アプリの起動や復帰時に、Firestore上に保存されている前回の稼働日（`business_date`）と現在の計算上の営業日を比較する。日付が変わっていることを検知した場合、前日の発注データを履歴コレクション（`order_history` / `hall_order_history`）に自動転送し、当日の発注数やチェック状態を初期目標値へ自動リセットする。

### 2. Firestoreリアルタイム同期とオフラインキャッシュ
* 発注状況（`working_orders/current` および `working_hall_orders/current`）は `snapshots()` を用いてStream購読している。複数端末で同時に発注数を増減させたりチェックを入れたりした場合でも、リアルタイムに画面が同期される。
* `persistenceEnabled: true` を設定してFirestoreのローカルキャッシュを有効化しており、店舗の地下等で一時的に電波が悪くなった場合でも入力データが失われないようオフライン対応を行っている。

### 3. Toreta予約に基づく必要食材量自動計算
翌日の予約人数とコース構成に基づき、必要食材の自動計算を行う。
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

## 📁 ディレクトリ構造と主要ファイル (Directory Tree)

```text
lib/
├── data/
│   ├── course_data.dart
│   ├── dish_data.dart
│   ├── hall_item_data.dart
│   ├── hall_order_data.dart
│   ├── item_data.dart
│   └── reservation_data.dart
├── models/
│   ├── course_recipe.dart
│   ├── dish.dart
│   ├── hall_item.dart
│   ├── item.dart
│   ├── order_item.dart
│   └── reservation.dart
├── pages/
│   ├── board_page.dart
│   ├── chief_page.dart
│   ├── course_edit_page.dart
│   ├── dish_edit_page.dart
│   ├── hall_confirm_page.dart
│   ├── hall_master_edit_page.dart
│   ├── hall_order_page.dart
│   ├── master_edit_page.dart
│   ├── memo_page.dart
│   ├── order_home_page.dart
│   ├── previous_order_page.dart
│   └── reservation_page.dart
├── utils/
│   └── date_utils.dart
├── firebase_options.dart
└── main.dart
```

---

## 📂 フォルダ・ファイル詳細仕様

### 📦 lib 直下 (エントリーポイント)

* **[main.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/main.dart)**
  * **役割**: アプリ起動のエントリーポイント。Firebase/Firestore初期化、ローカルキャッシュの設定、および起動時にFirestoreから全マスタデータ（発注品・ホール・料理・コース）を非同期ロードする。
  * **UI構成**: グリッドビュー形式の `TopMenuPage`。発注管理、ホール発注、予約状況確認、および各マスタ編集ページへのランチャーを担う。
* **[firebase_options.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/firebase_options.dart)**
  * **役割**: Firebase CLIによって自動生成されたプラットフォームごとの接続設定ファイル。

---

### 📂 lib/models (データモデル定義)

* **[item.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/models/item.dart)**
  * **役割**: 厨房・裏方発注品の定義モデル。
  * **プロパティ**: `id`(一意のID), `name`(商品名), `kitchen_minimum`(キッチンでの最低数), `back_minimum`(裏での最低数), `kitchen_category`(キッチンの保管カテゴリ), `back_category`(裏の保管カテゴリ), `supplier`(仕入先・並び順ID付き), `orderType`(発注担当: `OrderType` enum), `alive`(論理削除フラグ)。
* **[order_item.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/models/order_item.dart)**
  * **役割**: 実際の発注操作における作業状態を表すモデル。
  * **プロパティ**: `item`(対象の `Item`), `quantity`(発注数量), `inStock`(在庫ありチェックフラグ)。
  * **拡張 (`QuantityFormat`)**: double型を画面表示する際、`.0`を切り捨てて整数にしたり、小数の見栄えを一元的に整形する `toDisplayString()` メソッドを提供。
* **[hall_item.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/models/hall_item.dart)**
  * **役割**: ドリンクおよびホール補充・消耗品の定義・計算モデル。
  * **プロパティ**: `id`, `sameId`(ペアアイテム連動用), `name`, `category`, `targetOpened`/`targetUnopened`/`targetStock`(各目標値), `orderThreshold`(発注閾値), `orderUnit`(発注単位), `isSupply`(補充・消耗品判定), `opened`/`unopened`/`stock`(現在数), `isChecked`(補充発注有無), `manualAdjustment`(手動補正量), `userMemo`(ユーザー入力メモ)。
  * **主要メソッド**: `calculateTotalOrderAmount(List<HallItem> allItems)`:
    重複側アイテムを排除した上で、メインとペア（例: 冷蔵庫①の未開栓と冷蔵庫③のストック）の現在数の合計が `orderThreshold` 以下である場合に、不足数を計算して `orderUnit` の倍数に切り上げて発注数を導き出す。
* **[dish.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/models/dish.dart)**
  * **役割**: 料理の定義モデル。
  * **プロパティ**: `id`, `name`, `calcType`(計算タイプ), `memo`, `requiredItems`(食材IDと必要レート `DishItemRequirement` のマップ), `alive`(論理削除フラグ), `specialRule`(特例ルール識別名)。
* **[course_recipe.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/models/course_recipe.dart)**
  * **役割**: コースレシピ（コース構成）の定義モデル。
  * **プロパティ**: `id`, `courseName`(現場用呼称), `toretaKeyword`(Toreta連携用の正式名称), `dishIds`(紐付く料理のIDリスト), `alive`(論理削除フラグ)。
* **[reservation.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/models/reservation.dart)**
  * **役割**: Toreta APIから取得した予約情報の定義モデル。
  * **プロパティ**: `startTime`, `endTime`, `tableId`(卓番), `people`(予約人数), `course`(コース名・席のみの場合はnull), `note`(備考メモ)。

---

### 📂 lib/data (Firestore・外部通信連携)

* **[item_data.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/data/item_data.dart)**
  * **役割**: 厨房・裏方発注品マスタのFirestore通信。古いデータ構造（単一カテゴリ・単一最低数）を新構造へ自動移行しながらロードする `loadItemMaster()`、および一括保存する `saveItemMasterToLocal()` を備える。
* **[hall_item_data.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/data/hall_item_data.dart)**
  * **役割**: ホール商品マスタのFirestore通信。`loadHallItems()` では初回起動時の初期マスタデータの自動保存や、ドリンク系アイテム (`mockDrinkItems`) と補充系アイテム (`mockSupplyItems`) への仕分けを行う。
* **[hall_order_data.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/data/hall_order_data.dart)**
  * **役割**: ホール発注の作業中データ管理と履歴移行。日付跨ぎを検知し履歴にエスケープする `checkAndTransferHallHistory()`、および単一アイテムの状態をFirestoreにマージ保存する `updateSingleHallItem()` を定義。
* **[dish_data.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/data/dish_data.dart)**
  * **役割**: 料理マスタのFirestore通信。初期データの保存および `loadDishes()` によるロードを行う。
* **[course_data.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/data/course_data.dart)**
  * **役割**: コースマスタのFirestore通信。`loadCourseRecipes()` および一括保存 `saveCourseRecipesToLocal()` を実装。
* **[reservation_data.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/data/reservation_data.dart)**
  * **役割**: Python Cloud Functions APIとのHTTP通信。`.env` から `SECRET_API_KEY` を引き出してヘッダーにセットし、予約データをフェッチする `fetchTodayReservations()` を提供。

---

### 📂 lib/utils (共通ユーティリティ)

* **[date_utils.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/utils/date_utils.dart)**
  * **役割**: 朝6時日付切り替えロジックを集約。`getBusinessDate()` (DateTime型) および `getBusinessDateString()` (YYYY-MM-DD 文字列) を実装し、アプリケーション全体で一貫した営業日計算を提供する。

---

### 📂 lib/pages (画面定義)

#### 🍳 厨房・裏方発注フロー

* **[order_home_page.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/pages/order_home_page.dart)**
  * **役割**: 厨房・裏方用のメイン発注入力画面。
  * **主要機能**:
    * 朝6時営業日判定、日付変更時の自動履歴移行処理。
    * Firestore `working_orders` からのリアルタイム同期。
    * 明日の予約状況に基づく追加食材量の自動計算と表示（`+予約分: X`）。
    * 日曜日警告バナー（月曜定休のための2日分発注警告）の開閉表示。
    * 「キッチン側」「裏側」の表示モード切り替え（これに応じて表示するカテゴリ順序や、最低在庫数の切り替え、同期対象アイテムを動的制御）。
    * 発注用プルダウンおよび増減ボタンによる、400msデバウンスをかけたFirestore自動更新。
* **[board_page.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/pages/board_page.dart)**
  * **役割**: アルバイトスタッフ向けの「ホワイトボード書き写し」用画面。`OrderType.part` の商品で、発注数が1以上のもののみをシンプルな箇条書きで一覧表示する。
* **[chief_page.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/pages/chief_page.dart)**
  * **役割**: チーフ・仕入先別の確認画面。
  * **主要機能**:
    * `OrderType.chief` (チーフ発注) の商品を仕入先名（ハイフンより前の名称）でグループ化し、ハイフンの後ろの並び順IDでソートして表示。
    * `OrderType.owner` (オーナー発注、「とも兄さんにお願いするもの」) を別枠で下部に一覧表示。
* **[previous_order_page.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/pages/previous_order_page.dart)**
  * **役割**: 過去の発注履歴閲覧画面。
  * **主要機能**:
    * Firestore `order_history` コレクションのドキュメント一覧から、存在する年・月・日のプルダウンツリー構造を構築。
    * 選択した年月日（デフォルトは昨日）に確定された発注商品名と発注数量を表示する。
* **[memo_page.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/pages/memo_page.dart)**
  * **役割**: 現場用ローカルメモ画面。`SharedPreferences` を使用し、文字を入力するたびに端末ローカルに自動保存する。

#### 🍷 ホール発注フロー

* **[hall_order_page.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/pages/hall_order_page.dart)**
  * **役割**: ホールスタッフ向けの発注操作メイン画面。
  * **UI構成 (3タブ)**:
    1. **在庫入力タブ**: ワインを除くドリンク類の「開栓数」「未開栓数」（またはストック数）をカウント入力。カウンターは `-5`, `-1`, `+1`, `+5` の直感的な操作が可能。
    2. **発注数管理タブ**: 目標数から自動計算された発注数量に手動調整数を加味した最終発注数を表示・調整。発注数0の品目は半透明化。ワインについては専用の発注手動メモ入力UIを提供する。
    3. **補充タブ**: 消耗品や日曜日専用チェックアイテム（ガム、ナプキン、トイレ周りなど）のチェックボックス切り替え。
* **[hall_confirm_page.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/pages/hall_confirm_page.dart)**
  * **役割**: ホール発注の最終確認画面。
  * **主要機能**:
    * 発注数が1以上のドリンク、またはチェックされた消耗品、手動メモが存在するアイテムを抽出。
    * `名前に「キッチン」を含むもの` (キッチンに報告)、`カテゴリに「バー」を含むもの` (バーに報告)、`それ以外` (発注) の3つのセクションに自動的に仕分けてリスト化。
* **[hall_master_edit_page.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/pages/hall_master_edit_page.dart)**
  * **役割**: ホール商品マスタの追加・編集・削除画面。商品名、カテゴリ（ChoiceChipによる既存カテゴリ推薦）、目標数、発注閾値、発注単位、警告メモの編集をサポート。

#### 📋 マスタ編集・設定フロー

* **[master_edit_page.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/pages/master_edit_page.dart)**
  * **役割**: 厨房・裏方発注品マスタの追加・編集・削除画面。
  * **主要機能**:
    * 商品名、キッチン/裏方のそれぞれ個別のカテゴリと最低在庫数、発注担当区分（主任、パート、とも兄さんなど）、仕入先の編集。
    * 削除済みデータ（`alive: false`）からデータを呼び出して再登録するマスタ復元アシスト機能を搭載。
* **[dish_edit_page.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/pages/dish_edit_page.dart)**
  * **役割**: 料理マスタの追加・編集・削除画面。料理名、自動計算タイプ（比例・人数＝個数・段階・卓固定）、メモのほか、紐付く食材とその必要量、歩留まり、テーブル固定化トグルを料理ごとに細かく設定可能。
* **[course_edit_page.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/pages/course_edit_page.dart)**
  * **役割**: コースレシピマスタの追加・編集・削除画面。現場呼び名、Toreta検索用キーワードの編集、およびコースを構成する料理IDリストへの追加・削除が可能。

#### 📅 予約状況確認フロー

* **[reservation_page.dart](file:///c:/Users/81809/Desktop/tipu_order/tipu_order_app/lib/pages/reservation_page.dart)**
  * **役割**: Toreta連携による予約情報確認画面。
  * **主要機能**:
    * 卓番（テーブルID）を縦軸に、予約データを時間順に横方向のカードリストとして配置するマトリクス形式のレイアウト。
    * 予約カードをタップすることで、詳細ダイアログにToreta上の備考メモ全文を表示。
    * カレンダーダイアログからの日付選択表示切り替え。
    * 現場用ハンディ伝票印刷用のテキスト出力フォーマット生成（クリップボードコピー対応）。コース名の省略形への整形（「赤身天国コース」→「赤天」など）や、備考から「プレート」等の重要キーワードを自動抽出して強調するロジックを搭載。