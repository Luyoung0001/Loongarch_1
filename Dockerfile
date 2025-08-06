# 使用 Ubuntu 作为基础镜像
FROM ubuntu:22.04

# 避免交互式配置界面
ENV DEBIAN_FRONTEND=noninteractive

# 安装常见工具 + zsh
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    vim \
    zsh \
    build-essential \
    sudo \
    ca-certificates \
    locales \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 设置默认 locale 避免终端乱码
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# 设置默认用户（非 root）可选
# RUN useradd -m dev && echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# USER dev

# 设置默认 shell 为 zsh
SHELL ["/bin/zsh", "-c"]
CMD ["/bin/zsh"]

# 将当前目录（chiplab）复制进容器的 /workspace 目录
WORKDIR /workspace
COPY . /workspace

