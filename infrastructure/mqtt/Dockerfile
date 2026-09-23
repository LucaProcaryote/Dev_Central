# The stock broker plus a start-up script; no build step of our own.
FROM eclipse-mosquitto:2.0.20

COPY mosquitto.conf /mosquitto/config/mosquitto.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9001
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
