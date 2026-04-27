FROM alpine:3.23.4

ENV MISE_DATA_DIR="/mise" \
  MISE_CONFIG_DIR="/mise" \
  MISE_CACHE_DIR="/mise/cache" \
  MISE_INSTALL_PATH="/usr/local/bin/mise" \
  PI_HOME="/pi-home" \
  PI_DIR="/pi-home/.pi" \
  PI_SKIP_VERSION_CHECK="true"

ENV NPM_CONFIG_PREFIX=$PI_HOME/.pi/packages

ENV PATH="/mise/shims:$NPM_CONFIG_PREFIX/bin:$PI_DIR/node_modules/.bin:$PATH"

# add world readable and writeable directory for user to be able to install packages and persist sessions
RUN mkdir -p ${PI_DIR}/agent/sessions ${PI_DIR}/packages \
  && chmod -R 1777 ${PI_HOME}

# install packages
RUN apk add --no-cache \
  bash \
  curl \
  git \
  ca-certificates \
  build-base \
  fd \
  ripgrep \
  python3 \
  gnupg

# Install mise
RUN curl https://mise.run | sh

# Copy mise.toml configuration file
COPY mise.toml /mise/mise.toml

# Pre-install tools
RUN mise install

WORKDIR $PI_HOME/.pi

# Install pi
COPY package.json ./
RUN bun install --no-save --no-cache --production

ENTRYPOINT [ "/pi-home/.pi/node_modules/.bin/pi" ]
