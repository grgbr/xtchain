# Debian 12.x (bookworm)

DEBBINDEPS := latexmk texlive-latex-extra texlive-font-utils ca-certificates \
              graphviz

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
              latexmk texlive-latex-extra texlive-font-utils texlive-extra-utils \
              desktop-file-utils \
              automake \
              libtool \
              dejagnu \
              bison \
              flex \
              gettext \
              texinfo \
              libjson-c-dev \
              libzstd-dev \
              liblzma-dev \
              libbz2-dev \
              zlib1g-dev \
              libcurl4-gnutls-dev \
              libsysprof-4-dev \
              libarchive-dev \
              libsqlite3-dev \
              libmicrohttpd-dev \
              libmsgpack-dev \
              libxxhash-dev \
              libreadline-dev \
              libncurses-dev \
              libpython3-dev \
              libsource-highlight-dev \
              libbabeltrace-dev \
              libexpat1-dev \
              help2man \
              kyua \
              atf-sh \
              chrpath

DOCKIMG    := debian:bookworm-slim
