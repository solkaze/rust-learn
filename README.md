# Rust Cargo 練習環境構築リポジトリ

このリポジトリは、Rust のパッケージマネージャである Cargo を使ったプロジェクトの練習環境を提供します。Docker と Visual Studio Code の DevContainer 機能を利用して、簡単に開発環境をセットアップできます。

## 機能

- Rust と Cargo のインストール済み環境
- Docker コンテナ内での開発環境構築
- VSCode DevContainer サポート

## 使い方
1. リポジトリをクローンします。

```bash
git clone https://github.com/your-username/rust-cargo-practice.git
cd rust-cargo-practice
```

2. Docker と VSCode をインストールします。
3. VSCode でリポジトリを開き、DevContainer 機能を使用してコンテナ内で開発環境を起動します。
4. コンテナ内で Rust と Cargo を使用してプロジェクトを作成・管理します。
```bash
cargo new my_project
cd my_project
cargo build
cargo run
```

## よく使うCargoコマンド
- `cargo new <project_name>`: 新しい Rust プロジェクトを作成します。
- `cargo build`: プロジェクトをビルドします。
- `cargo run`: プロジェクトをビルドして実行します。
- `cargo test`: プロジェクトのテストを実行します。
- `cargo add <dependency>`: プロジェクトに依存関係を追加します。（`cargo-edit` クレートが必要です）
- `cargo update`: 依存関係を最新バージョンに更新します。
- `cargo clean`: ビルド成果物を削除します。
- `cargo doc --open`: プロジェクトのドキュメントを生成し、ブラウザで開きます。