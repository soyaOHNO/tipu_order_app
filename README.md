# 発注管理アプリ

焼肉店における発注業務を支援するためのアプリケーションです。

現在は紙で行っている発注チェック表をデジタル化し、発注履歴の保存や必要数量の計算を行うことを目的としています。

## URL
* ![https://tipu-order.web.app](https://tipu-order.web.app)

## 主な機能

* 商品ごとの発注数入力
* 発注履歴の保存
* 商品マスタ管理
* toretaから予約状況の取得(未実装)
* コース人数に応じた必要数量の計算(仮)
* 発注内容の確認

## 開発背景

現在、発注業務は紙媒体で管理されています。

紙による管理では、

* 過去の発注履歴を確認しにくい
* 発注量の傾向分析ができない
* 予約状況を考慮した計算が手作業になる

といった課題があります。

本アプリでは、まず紙運用をそのままデジタル化し、将来的には予約情報を活用した発注支援機能の実装を目指しています。

## 今後の予定

### Phase 1

* TORETA予約情報連携
* コース情報の自動取得

### Phase 2

* POS連携
* 注文履歴の参照

### Phase 3

* 発注履歴の分析
* XGBoostを利用した需要予測


## 技術構成（予定）

* Flutter
* Dart
* ローカルデータベース


## Build
* flutter build web --release
* firebase init hosting
What do you want to use as your public directory? (公開フォルダはどこにする？)
👉 build/web と入力してエンター（※デフォルトの public のままにしないよう注意！）

Configure as a single-page app (rewrite all urls to /index.html)?
👉 y (Yes)

Set up automatic builds and deploys with GitHub?
👉 n (No)

File build/web/index.html already exists. Overwrite? (上書きする？)
👉 n (No！絶対に上書きしないでください。Flutterが作った index.html が消えてしまいます)
* firebase deploy --only hosting

## Update
* flutter build web --release
* firebase deploy --only hosting