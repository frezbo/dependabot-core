FROM ubuntu:18.04

### SYSTEM DEPENDENCIES

ENV DEBIAN_FRONTEND="noninteractive" \
    LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8"

# Everything from `make` onwards in apt-get install is only installed to ensure
# Python support works with all packages (which may require specific libraries
# at install time).

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
      build-essential \
      dirmngr \
      git \
      bzr \
      mercurial \
      gnupg2 \
      curl \
      wget \
      zlib1g-dev \
      liblzma-dev \
      tzdata \
      zip \
      unzip \
      locales \
      openssh-client \
      make \
      libpq-dev \
      libssl-dev \
      libbz2-dev \
      libffi-dev \
      libreadline-dev \
      libsqlite3-dev \
      libcurl4-openssl-dev \
      llvm \
      libncurses5-dev \
      libncursesw5-dev \
      libmysqlclient-dev \
      xz-utils \
      tk-dev \
      libxml2-dev \
      libxmlsec1-dev \
      libgeos-dev \
      python3-enchant \
    && locale-gen en_US.UTF-8


### RUBY

# Install Ruby 2.6.5, update RubyGems, and install Bundler
ENV BUNDLE_SILENCE_ROOT_WARNING=1
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C3173AA6 \
    && echo "deb http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu bionic main" > /etc/apt/sources.list.d/brightbox.list \
    && apt-get update \
    && apt-get install -y ruby2.6 ruby2.6-dev \
    && gem update --system 3.0.3 \
    && gem install bundler -v 1.17.3 --no-document


### PYTHON

# Install Python 2.7 and 3.8 with pyenv. Using pyenv lets us support multiple Pythons
ENV PYENV_ROOT=/usr/local/.pyenv \
    PATH="/usr/local/.pyenv/bin:$PATH"
RUN git clone https://github.com/pyenv/pyenv.git /usr/local/.pyenv \
    && cd /usr/local/.pyenv && git checkout cf81e5a0c47ab09d8f760e2bb9172196d9602fde && cd - \
    && pyenv install 3.8.3 \
    && pyenv install 2.7.18 \
    && pyenv global 3.8.3


### JAVASCRIPT

# Install Node 10.0 and Yarn
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && apt-get install -y nodejs \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update && apt-get install -y yarn


### ELM

# Install Elm 0.18 and Elm 0.19
ENV PATH="$PATH:/node_modules/.bin"
RUN npm install elm@0.18.0 \
    && wget "https://github.com/elm/compiler/releases/download/0.19.0/binaries-for-linux.tar.gz" \
    && tar xzf binaries-for-linux.tar.gz \
    && mv elm /usr/local/bin/elm19 \
    && rm -f binaries-for-linux.tar.gz


### PHP

# Install PHP 7.4 and Composer
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu bionic main" >> /etc/apt/sources.list.d/ondrej-php.list \
    && echo "deb-src http://ppa.launchpad.net/ondrej/php/ubuntu bionic main" >> /etc/apt/sources.list.d/ondrej-php.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C \
    && apt-get update \
    && apt-get install -y php7.4 php7.4-cli php7.4-xml php7.4-json php7.4-zip php7.4-mbstring php7.4-intl php7.4-common php7.4-gettext php7.4-curl php7.4-bcmath php7.4-gmp php7.4-imagick php7.4-gd php7.4-redis php7.4-soap php7.4-ldap php7.4-memcached php7.4-sqlite3 php7.4-apcu php7.4-tidy php7.4-mongodb php7.4-zmq php7.4-mysql php7.4-imap php7.4-geoip \
    && curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer


### GO

# Install Go and dep
RUN curl https://dl.google.com/go/go1.13.4.linux-amd64.tar.gz | tar -xz -C /opt \
    && wget -O /opt/go/bin/dep https://github.com/golang/dep/releases/download/v0.5.4/dep-linux-amd64 \
    && chmod +x /opt/go/bin/dep \
    && mkdir /opt/go/gopath
ENV PATH=/opt/go/bin:$PATH GOPATH=/opt/go/gopath


### ELIXIR

# Install Erlang, Elixir and Hex
ENV PATH="$PATH:/usr/local/elixir/bin"
RUN wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb \
    && dpkg -i erlang-solutions_1.0_all.deb \
    && apt-get update \
    && apt-get install -y esl-erlang \
    && wget https://github.com/elixir-lang/elixir/releases/download/v1.9.1/Precompiled.zip \
    && unzip -d /usr/local/elixir -x Precompiled.zip \
    && rm -f Precompiled.zip \
    && mix local.hex --force


### RUST

# Install Rust 1.37.0
ENV RUSTUP_HOME=/opt/rust \
    PATH="${PATH}:/opt/rust/bin"
RUN export CARGO_HOME=/opt/rust ; curl https://sh.rustup.rs -sSf | sh -s -- -y


### NEW NATIVE HELPERS

COPY terraform/helpers /opt/terraform/helpers
COPY python/helpers /opt/python/helpers
COPY dep/helpers /opt/dep/helpers
COPY go_modules/helpers /opt/go_modules/helpers
COPY hex/helpers /opt/hex/helpers
COPY composer/helpers /opt/composer/helpers
COPY npm_and_yarn/helpers /opt/npm_and_yarn/helpers

ENV DEPENDABOT_NATIVE_HELPERS_PATH="/opt" \
    PATH="$PATH:/opt/terraform/bin:/opt/python/bin:/opt/go_modules/bin:/opt/dep/bin" \
    MIX_HOME="/opt/hex/mix"

RUN bash /opt/terraform/helpers/build /opt/terraform && \
    bash /opt/python/helpers/build /opt/python && \
    bash /opt/dep/helpers/build /opt/dep && \
    bash /opt/go_modules/helpers/build /opt/go_modules && \
    bash /opt/npm_and_yarn/helpers/build /opt/npm_and_yarn && \
    bash /opt/hex/helpers/build /opt/hex && \
    bash /opt/composer/helpers/build /opt/composer
