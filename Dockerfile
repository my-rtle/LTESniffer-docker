FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Seoul
WORKDIR /opt

# -------------------------
# 0) 공통 빌드/런타임 패키지
# -------------------------
RUN apt update && apt-get install -y \
  ca-certificates curl wget gnupg lsb-release sudo git \
  build-essential ccache cmake pkg-config \
  autoconf automake doxygen ethtool inetutils-tools \
  libboost-all-dev \
  libusb-1.0-0 libusb-1.0-0-dev libusb-dev \
  libncurses5 libncurses5-dev \
  python3-dev python3-pip python3-mako python3-numpy python3-requests python3-scipy python3-setuptools \
  python3-ruamel.yaml \
  # srsRAN deps
  libfftw3-dev libmbedtls-dev libboost-program-options-dev libconfig++-dev libsctp-dev \
  # LTESniffer deps
  libglib2.0-dev libudev-dev libcurl4-gnutls-dev \
  qtdeclarative5-dev libqt5charts5-dev \
  && rm -rf /var/lib/apt/lists/*

# -------------------------
# 1) UHD (>=4.0) 소스 빌드/설치
# -------------------------
ARG UHD_REPO=https://github.com/EttusResearch/uhd.git
ARG UHD_BRANCH=master

RUN git clone --depth 1 --branch ${UHD_BRANCH} ${UHD_REPO} /opt/uhd \
  && cd /opt/uhd/host \
  && mkdir -p build && cd build \
  && cmake ../ \
  && make -j"$(nproc)" \
  && ctest --output-on-failure || true \
  && make install \
  && ldconfig


# -------------------------
# 2) LTESniffer 소스 받기 + 다운링크/업링크 각각 빌드
# -------------------------
ARG LTESNIFFER_REPO=https://github.com/SysSec-KAIST/LTESniffer.git
# 다운링크(메인) 기준: master/main 중 실제 기본 브랜치명으로 맞춰도 됨
ARG LTESNIFFER_REF_MAIN=main
# 업링크: 멀티 USRP 브랜치
ARG LTESNIFFER_REF_MULTI=LTESniffer-multi-usrp

RUN git clone ${LTESNIFFER_REPO} /opt/LTESniffer

# 2-1) 다운링크 빌드 (main)
RUN cd /opt/LTESniffer \
  && git fetch --all --tags \
  && git checkout ${LTESNIFFER_REF_MAIN} \
  && mkdir -p /opt/LTESniffer-build-dl \
  && cd /opt/LTESniffer-build-dl \
  && cmake /opt/LTESniffer \
  && make -j"$(nproc)"

# 2-2) 업링크 빌드 (multi branch)
RUN cd /opt/LTESniffer \
  && git checkout ${LTESNIFFER_REF_MULTI} \
  && mkdir -p /opt/LTESniffer-build-ul \
  && cd /opt/LTESniffer-build-ul \
  && cmake /opt/LTESniffer \
  && make -j"$(nproc)"

# 기본은 쉘로 들어가게
CMD ["bash"]
