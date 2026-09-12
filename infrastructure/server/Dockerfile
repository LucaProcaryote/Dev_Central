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

EXPOSE 8081
ENTRYPOINT ["/app/bin/server"]
