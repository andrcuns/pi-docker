FROM debian:13.4-slim

ENV PI_HOME="/home/pi" \
  PI_DIR="/home/pi/.pi" \
  PI_SKIP_VERSION_CHECK="true"

ENV MISE_DATA_DIR="${PI_HOME}/.local/share/mise" \
  MISE_CONFIG_DIR="${PI_HOME}/.config/mise" \
  MISE_CACHE_DIR="${PI_HOME}/.cache/mise"

# set global tool paths so that tooling can be persisted across sessions
ENV NPM_CONFIG_PREFIX=${PI_DIR}/packages/npm \
  BUN_INSTALL=${PI_HOME}/packages/bun \
  GEM_HOME=${PI_DIR}/packages/gems \
  PYTHONUSERBASE=${PI_DIR}/packages/python

ENV PATH="/home/pi/.local/bin:${MISE_DATA_DIR}/shims:$PATH"

# Create user with UID and GID
ARG UID=1000
ARG GID=1000
RUN groupadd -g ${GID} pi && useradd -m -u ${UID} -g ${GID} pi && chown -R ${UID}:${GID} ${PI_HOME}

# add world readable and writeable directory for user to be able to install packages and persist sessions
RUN set -e; \
  mkdir -p ${PI_DIR}/agent ${PI_DIR}/packages \
  && chown -R pi:pi ${PI_DIR} ${PI_DIR}/packages ${PI_DIR}/agent

# install packages
RUN apt-get update  \
  && apt-get -y --no-install-recommends install  \
  curl \
  git \
  ca-certificates \
  build-essential \
  ripgrep \
  fd-find \
  && rm -rf /var/lib/apt/lists/*

USER pi
WORKDIR ${PI_DIR}

# install mise
ARG MISE_VERSION
RUN curl https://mise.run | sh

# copy mise.toml configuration file
COPY mise.toml ${MISE_CONFIG_DIR}/mise.toml

# pre-install tools
RUN mise install

# install pi harness
COPY --chown=pi:pi package.json ${PI_DIR}/package.json
RUN bun install --no-cache --no-save --unhandled-rejections=strict

ENTRYPOINT [ "/home/pi/.pi/node_modules/.bin/pi" ]
