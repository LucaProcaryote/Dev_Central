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

# Not `FROM scratch` + Dart's own /runtime/, which is what the Dart
# documentation suggests and what this used to do.
#
# On Cloud Run that image started, bound its port and passed the TCP health
# probe - and then did nothing at all. No request was ever logged, and the
# start-up line that follows `Listening` by one second locally never
# appeared. Alive, listening, and not running. The same binary, compiled the
# same way, works locally; the difference is what is around it.
#
# distroless/cc carries a glibc, libssl and the CA bundle, and nothing else -
# no shell, no package manager. Same Debian 12 as the dart:3.9 build stage,
# so the AOT binary finds the libc it was linked against.
FROM gcr.io/distroless/cc-debian12
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
