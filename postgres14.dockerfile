FROM ghcr.io/hotosm/postgres:14-http
COPY files/postgres14/start-postgres.sh /usr/local/bin/


# PGDATA is originally declared in the parent Dockerfile, but points
# to an anonymous VOLUME declaration in the same file:
#
#   ENV PGDATA /var/lib/postgresql/data
#   ...
#   VOLUME /var/lib/postgresql/data
#
# To ensure future accessibility, PGDATA must be stored _outside_ the
# anonymous volume.

ENV PGDATA=/var/lib/odk/postgresql/14/data

COPY <<EOF /docker-entrypoint-initdb.d/init-http.sql
CREATE EXTENSION IF NOT EXISTS http;
EOF

ENTRYPOINT []
CMD ["start-postgres.sh"]