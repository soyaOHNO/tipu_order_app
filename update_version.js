// 最新の firebase-admin (v12+) の書き方
const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

// 鍵を読み込む
const serviceAccount = require("./serviceAccountKey.json");

// Firebase管理者として初期化
initializeApp({
  credential: cert(serviceAccount)
});

// PowerShellから渡されたバージョン番号を受け取る
const version = process.argv[2];
const db = getFirestore();

if (!version) {
  console.error("❌ エラー: バージョンが指定されていません。");
  process.exit(1);
}

// Firestoreの 'app_info/version' を更新する
db.collection("app_info").doc("version").set({
  latest_version: version
}, { merge: true })
.then(() => {
  console.log(`✅ Firestoreの最新バージョンを [ ${version} ] に更新しました！`);
  process.exit(0);
})
.catch((error) => {
  console.error("❌ Firestoreの更新に失敗しました:", error);
  process.exit(1);
});