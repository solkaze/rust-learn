# ./Dockerfile
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# タイムゾーン & ロケール設定
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone

RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    && locale-gen ja_JP.UTF-8 \
    && update-locale LANG=ja_JP.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=ja_JP.UTF-8 \
    LANGUAGE=ja_JP:ja \
    LC_ALL=ja_JP.UTF-8

# 共通ツール系
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake ninja-build \
    tzdata ca-certificates \
    git wget curl unzip less sudo \
    vim \
    pkg-config build-essential \
    lldb \
    zsh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Rust / Cargo を全ユーザー共有ディレクトリにインストール
# 公式 rustup スクリプトを利用
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo
ENV PATH=${CARGO_HOME}/bin:${PATH}

RUN set -eux; \
    curl -sSf https://sh.rustup.rs | \
        sh -s -- -y --no-modify-path --default-toolchain stable; \
    # 全ユーザーが使えるように権限調整
    chmod -R a+rwx ${RUSTUP_HOME} ${CARGO_HOME}

# Rustの便利ツール（全ユーザーで利用可）
RUN rustup component add rustfmt clippy

# xterm-kitty terminfo をコンテナにコピーして登録
COPY xterm-kitty.terminfo /tmp/xterm-kitty.terminfo
RUN tic /tmp/xterm-kitty.terminfo && rm /tmp/xterm-kitty.terminfo

# 非rootユーザー（ホストのUID/GIDに合わせられる）
# --- ユーザー設定（RUN より前に必ず置く）---
ARG USER_ID=1000
ARG GROUP_ID=1000

# --- ユーザー・グループ作成ロジック ---

RUN set -eux; \
    # group: 存在しなければ作る
    if ! getent group "${GROUP_ID}" >/dev/null; then \
        groupadd --gid "${GROUP_ID}" user; \
    else \
        echo "Group ${GROUP_ID} already exists ($(getent group ${GROUP_ID} | cut -d: -f1))"; \
    fi; \
    \
    # user: 存在しなければ作る
    if ! getent passwd "${USER_ID}" >/dev/null; then \
        useradd --uid "${USER_ID}" --gid "${GROUP_ID}" -m -s /bin/bash user; \
    else \
        echo "User ${USER_ID} already exists ($(getent passwd ${USER_ID} | cut -d: -f1))"; \
    fi; \
    \
    # sudo 権限付与（UID→実ユーザー名を取得）
    EXISTING_USER=$(getent passwd "${USER_ID}" | cut -d: -f1); \
    usermod -aG sudo "${EXISTING_USER}"; \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/010-sudo-nopasswd; \
    chmod 0440 /etc/sudoers.d/010-sudo-nopasswd

# ここで p10k を /tmp にコピー（まだ root）
COPY .devcontainer/.p10k.zsh /tmp/.p10k.zsh

# root のうちにホームディレクトリに配置して chown する
RUN set -eux; \
    user_home="$(getent passwd "${USER_ID}" | cut -d: -f6)"; \
    cp /tmp/.p10k.zsh "${user_home}/.p10k.zsh"; \
    chown "${USER_ID}:${GROUP_ID}" "${user_home}/.p10k.zsh"; \
    rm /tmp/.p10k.zsh

# ここから非rootユーザーに切り替え
USER ${USER_ID}:${GROUP_ID}
WORKDIR /workspace

# oh-my-zsh インストール
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

RUN echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> ~/.zshrc

# powerlevel10k テーマを oh-my-zsh に追加
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    ~/.oh-my-zsh/custom/themes/powerlevel10k && \
    sed -i 's|ZSH_THEME=".*"|ZSH_THEME="powerlevel10k/powerlevel10k"|' ~/.zshrc

# 外部 zsh プラグインのインストール
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    git clone https://github.com/zsh-users/zsh-history-substring-search ~/.oh-my-zsh/custom/plugins/history-substring-search && \
    git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions

# plugins 設定を差し替え
RUN sed -i 's/^plugins=.*/plugins=(\
    git \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    history-substring-search \
    zsh-completions \
    command-not-found \
    gitignore \
    aliases \
    docker \
    copyfile \
    copypath \
)/' ~/.zshrc

# ビルドアーティファクトをプロジェクト直下に固定（便利）
ENV CARGO_TARGET_DIR=/workspace/target

CMD ["/usr/bin/zsh"]
