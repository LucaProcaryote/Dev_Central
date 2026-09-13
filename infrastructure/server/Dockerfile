# The API server, compiled to a single native binary.
#
# Two stages: the first compiles, the second carries only the executable, so
# the runtime image has no Dart SDK and nothing else to keep patched.
FROM dart:3.9 AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# `scratch` would work for a statically linked binary, but Dart's AOT output
# needs a libc, so use the runtime image Dart publishes for exactly this.
#
# This was briefly changed to distroless/cc-debian12 on the theory that the
# minimal image was why the service started, listened, passed its health probe
# and then answered nothing. The timestamps say otherwise: the one time the
# service ever answered - `pong`, 17:10 - it was running this image, and the
# first distroless build never answered at all. The theory was wrong and the
# change made things worse, so it is reverted.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

# Which application this instance serves is set per service in the compose
# file; the defaults here make `docker run` on its own do something sensible.
ENV APP=EHR
ENV DB_HOST=postgres
ENV DB_PORT=5432
ENV DB_USER=hospital
ENV DB_PASSWORD=hospital

# Cloud Run sets PORT and the server honours it; this is only for `docker run`.
EXPOSE 8081
ENTRYPOINT ["/app/bin/server"]
