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

# `scratch` plus Dart's own /runtime/ is what the Dart documentation suggests,
# and it works. So does this. Both were suspected, in turn, of being why the
# service starts on Cloud Run, listens, passes its health probe and then
# answers nothing - and the suspicion was wrong both times.
#
# This exact image, pulled by digest and run with `docker run`, answers /ping
# in under a millisecond and reports the database error on /health. Whatever
# silences it on Cloud Run is not in here.
#
# distroless/cc it is, then: a real glibc, libssl and the CA bundle, on the
# same Debian 12 as the dart:3.9 build stage, maintained by someone else. The
# only base we have actually watched serve a request from inside a container.
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
