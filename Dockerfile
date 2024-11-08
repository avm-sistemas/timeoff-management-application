# -------------------------------------------------------------------
# Dockerfile do projeto Timeoff-Management-Applications
#
# Instructions:
# =============
# 1. Create image with: 
#	docker build --tag timeoff-management-application:latest .
#
# 2. Run with: 
#	docker run -d -p 4000:4000 --name alpine_timeoff timeoff-management-application
#
# 3. Login to running container (to update config (vi config/app.json): 
#	docker exec -ti --user root alpine_timeoff /bin/sh
# --------------------------------------------------------------------
FROM debian:latest as debian-node14

# #######################################################
# INIT
# #######################################################
# FOR�A o APT-GET a se interar sobre as novidades
RUN apt-get update

# INSTALA ferramentas de usar HTTPS no debian
RUN apt-get install -y apt-transport-https \
    ca-certificates \
    curl gnupg2 \
    software-properties-common

# INSTALA o certificado GPGP do reposit�rio NODESOURCE
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -

# #######################################################
# VARIAVEL DE AMBIENTE PARA O LINUX
# #######################################################

ENV DEBIAN_FRONTEND=noninteractive
ARG DEBIAN_FRONTEND=noninteractive

# CUSTOM CACHE INVALIDATION
ENV CACHEBUST=1
ARG CACHEBUST=1

# #######################################################
# APT-GET
# #######################################################

# FOR�A o APT-GET a re-atualizar as fontes de dados com a nova de NODESOURCE
RUN apt-get update
# INSTALA o APT-UTILS
RUN apt-get install -y --no-install-recommends apt-utils 
# INSTALA O NODE 14, estabelecido perlo certificado GPGP
RUN apt-get install -y --no-install-recommends nodejs
# INSTALA o vim para facilitar caso seja necess�rio depurar
RUN apt-get install -y --no-install-recommends vim
# INSTALA o midnight commander para facilitar a visualiza��o dos ficheiros em runtime
RUN apt-get install -y --no-install-recommends mc
# INSTALA a base do python (Necess�rio para instalar a biblioteca do sqlite3)
RUN apt-get install -y --no-install-recommends python
# INSTALA o pacote build-essential que possui as mais comuns biblioteca e ferramentas de compila��o, at� do kernel, se preciso.
RUN apt-get install -y --no-install-recommends build-essential
# INSTALA o supervisor. O supervisor funciona como um orquestrador do processo e, se perceber que o app est� fora do ar, ele mata o processo e auto-executa.
RUN apt-get install -y --no-install-recommends supervisor
# INSTALA o SUDO
RUN apt-get install -y sudo

# #######################################################
# APP
# #######################################################

# INSTALAMOS TUDO. Agora copiamos tudo do projeto para a pasta atual
COPY package.json  .
# PEDIMOS AO NODE que configure o projeto para runtime
RUN npm install 
# PEDIMOS que o NODE inclua a biblioteca para MYSQL na biblioteca de runtime
RUN npm install mysql --save
# PEDIMOS que o NODE inclua a biblioteca para SQLITE3 na biblioteca de runtime
RUN npm install sqlite3 --save

# INSTALA o NODEMON usado na depuracao (caso necess�rio)
RUN sudo npm install nodemon -g

# INSTALA o ORQUESTRADOR com privil�gios de root
RUN sudo npm install pm2 -g

# Imagem "dependencias" montada com as ferramentas necess�rias e o c�digo-fonte!
# Hora de iniciar a montagem e execu��o da aplica��o em cima desta imagem rec�m criada...
FROM debian-node14 as debian-node14-app

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.docker.cmd="docker run -d -p 4000:4000 --name timeoff-management-application --tag timeoff-management-application:latest"

RUN adduser --system app --home /app
USER app
WORKDIR /app
COPY --chmod=765 . /app
COPY --chmod=765 --from=dependencies node_modules ./node_modules
COPY --chmod=777 ./startup-*.sh /app

# LISTA o ROOT APLICACIONAL
# RUN ls -lsh

# #######################################################
# EXECU��O
# #######################################################

#ENV PORT=4000
#ENV NODE_ENV=development
#ENV NODE_DEBUG=i18n:*,cluster,net,http,fs,tls,module,timers,node,app.js

# PONTO DE EXECU��O
#ENTRYPOINT [ "startup-dev.sh" ]
#CMD ["startup-dev.sh"]

CMD ./startup-dev.sh

EXPOSE 4000
