FROM erlang:21

# elixir expects utf8.
ENV ELIXIR_VERSION="v1.7.2" \
  LANG=C.UTF-8

# RUN set -xe \
#   && ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION}.tar.gz" \
#   && ELIXIR_DOWNLOAD_SHA256="c12a4931a5383a8a9e9eb006566af698e617b57a1f645a6cb132a321b671292d" \
#   && curl -fSL -o elixir-src.tar.gz $ELIXIR_DOWNLOAD_URL \
#   && echo "$ELIXIR_DOWNLOAD_SHA256  elixir-src.tar.gz" | sha256sum -c - \
#   && mkdir -p /usr/local/src/elixir \
#   && tar -xzC /usr/local/src/elixir --strip-components=1 -f elixir-src.tar.gz \
#   && rm elixir-src.tar.gz \
#   && cd /usr/local/src/elixir \
#   && make install clean
# elixir expects utf8.
ENV ELIXIR_VERSION="v1.7.2" \
	LANG=C.UTF-8

RUN set -xe \
	&& ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION#*@}.tar.gz" \
	&& ELIXIR_DOWNLOAD_SHA256="3258eca6b5caa5e98b67dd033f9eb1b0b7ecbdb7b0f07c111b704700962e64cc" \
	&& curl -fSL -o elixir-src.tar.gz $ELIXIR_DOWNLOAD_URL \
	&& echo "$ELIXIR_DOWNLOAD_SHA256  elixir-src.tar.gz" | sha256sum -c - \
	&& mkdir -p /usr/local/src/elixir \
	&& tar -xzC /usr/local/src/elixir --strip-components=1 -f elixir-src.tar.gz \
	&& rm elixir-src.tar.gz \
	&& cd /usr/local/src/elixir \
	&& make install clean


# install hex package manager
RUN mix local.hex --force

# install the latest phoenix
RUN mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez

# install node
RUN curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh
RUN bash nodesource_setup.sh
RUN apt-get install -y nodejs
RUN apt-get install -y inotify-tools
RUN apt-get install -y vim
RUN apt-get install -y make
RUN npm i -g webpack@3.6.0

# create app folder
RUN mkdir /app
COPY . /app
WORKDIR /app

# install dependencies
RUN mix local.hex --force
RUN mix local.rebar --force
