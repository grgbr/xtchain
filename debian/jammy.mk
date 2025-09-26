# Ubuntu 22.04 (jammy)

DEBBINDEPS := latexmk texlive-latex-extra texlive-font-utils ca-certificates \
              graphviz libnsl2

DEBSRCDEPS := lsb-release \
              curl \
              file \
              gpg \
              tar gzip bzip2 xz-utils lzip unzip \
              patch \
              diffutils \
              procps \
              rsync \
              fakeroot \
              grep sed gawk \
              make gcc g++ \
              netbase \
              git \
              ca-certificates \
              rustc \
              cargo \
              latexmk texlive-latex-extra texlive-font-utils \
              desktop-file-utils

DOCKIMG    := ubuntu:jammy
