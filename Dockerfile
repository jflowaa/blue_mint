FROM elixir:1.16.3-otp-26-slim AS build

ENV MIX_ENV=prod \
    ERL_FLAGS="+JMsingle true" \
    LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential git ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

COPY config config
COPY priv priv
COPY lib lib
COPY assets assets

RUN mix assets.setup \
 && mix assets.deploy \
 && mix release

FROM debian:trixie-slim AS app

ENV LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    MIX_ENV=prod \
    PHX_SERVER=true \
    HOME=/app

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl libncurses6 libstdc++6 openssl tzdata \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd --gid 10001 app \
 && useradd --uid 10001 --gid app --create-home --home-dir /app app

WORKDIR /app

COPY --from=build --chown=app:app /app/_build/prod/rel/blue_mint ./

USER 10001:10001

EXPOSE 4001

ENTRYPOINT ["/app/bin/blue_mint"]
CMD ["start"]
