# ./Dockerfile
FROM rust:1-bookworm

ENV DEBIAN_FRONTEND=noninteractive TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone

RUN apt-get update && apt-get install -y --no-install-recommends locales \
 && sed -i 's/^# *ja_JP.UTF-8/ja_JP.UTF-8/' /etc/locale.gen \
 && locale-gen ja_JP.UTF-8 en_US.UTF-8 \
 && update-locale LANG=ja_JP.UTF-8 LC_ALL=ja_JP.UTF-8
ENV LANG=ja_JP.UTF-8 LC_ALL=ja_JP.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    tzdata ca-certificates \
    git wget curl unzip less sudo \
    pkg-config build-essential \
    # デバッグしたくなった時用（任意だが入れとくと便利）
    lldb \
 && rm -rf /var/lib/apt/lists/*

# Rustの便利ツール（全ユーザーで利用可）
RUN rustup component add rustfmt clippy

# 非rootユーザー（ホストのUID/GIDに合わせられる）
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000
RUN set -eux; \
  groupadd --gid ${USER_GID} ${USERNAME} || true; \
  useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} || true; \
  usermod -aG sudo ${USERNAME}; \
  echo '%sudo ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/010-sudo-nopasswd; \
  chmod 0440 /etc/sudoers.d/010-sudo-nopasswd; \
  mkdir -p /workspace; \
  chown -R ${USER_UID}:${USER_GID} /workspace /opt /usr/local

ENV HOME=/home/${USERNAME}
WORKDIR /workspace

USER ${USERNAME}

# cargo/rustup PATH（rust:1 では /usr/local/cargo/bin にある）
ENV PATH="/usr/local/cargo/bin:${PATH}"

# ビルドアーティファクトをプロジェクト直下に固定（便利）
ENV CARGO_TARGET_DIR=/workspace/target
