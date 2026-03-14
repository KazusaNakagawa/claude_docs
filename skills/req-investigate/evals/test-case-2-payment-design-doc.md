# 設計書 — EC決済システム

## 概要
Stripe と PayPay を使ったオンライン決済システム。月間取引件数 約1万件。

## 技術的実現可否
**判断: 条件付き対応可能**
- Stripe は公式 API あり、実績も豊富
- PayPay は法人契約が必要、申請フローが不明

## アーキテクチャ方針
- バックエンド: Python + FastAPI
- 決済: Stripe API + PayPay API
- 環境: AWS Lambda

## 不明点・確認事項
1. PayPay の法人向けAPI契約条件が不明
2. Stripe の日本円決済手数料の詳細
3. 定期課金（サブスクリプション）機能の要否
4. 決済データの保持期間・PCI DSS 対応要件
