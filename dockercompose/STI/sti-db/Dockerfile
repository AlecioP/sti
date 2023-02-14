ARG postgres_v=15.1
FROM postgres:${postgres_v}

WORKDIR /root

ARG sti_v=v0.9-alpha-docker
ARG sti_repo=https://github.com/aleciop/sti/releases/download/${sti_v}

ADD ${sti_repo}/lportal.sql /root

CMD su postgres -c "postgres"

RUN psql -U postgres -c "create user sti_cts2 with encrypted password 'sti_cts2' nosuperuser nocreatedb nocreaterole login ;"

RUN psql -U postgres -c "create database lportal with owner sti_cts2;"

RUN psql lportal < /root/lportal.sql