FROM node:21.1.0-bookworm

WORKDIR /usr/src/app

COPY . .

ENV PM2_HOME=/tmp

RUN set -ex \
    && yarn install \
    && yarn global add pm2 \
    && chmod +x entrypoint.sh \
    && curl -fsSLO --compressed "https://github.com/SagerNet/sing-box/releases/download/v1.5.3/sing-box-1.5.3-linux-amd64.tar.gz" \
    && tar -zxvf sing-box* \
    && cd sing-box-1.5.3-linux-amd64 \
    && EXEC=$(echo $RANDOM | md5sum | head -c 4) \
    && mv sing-box app${EXEC} \
    && rm -rf sing-box \
    && mv app* ../ \
    && addgroup --gid 10014 choreo \
    && adduser --disabled-password  --no-create-home --uid 10014 --ingroup choreo choreouser \
    && usermod -aG sudo choreouser
   
USER 10014

ENTRYPOINT ["yarn", "start"]
