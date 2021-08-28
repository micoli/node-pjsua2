FROM python:3.6-slim-stretch as base

FROM base AS build
ARG VERSION_PJSIP=2.9
ENV JAVA_HOME /usr/lib/jvm/default-java/

#Hack for JDK install:
RUN mkdir -p /usr/share/man/man1

RUN apt-get update \
    && apt-get install \
    build-essential \
    default-jdk  \
    swig \
    wget \
    libasound2-dev \
    libssl-dev \
    libv4l-dev \
    libsdl2-dev \
    libsdl2-gfx-dev \
    libsdl2-image-dev \
    libsdl2-mixer-dev \
    libsdl2-net-dev \
    libsdl2-ttf-dev \
    libx264-dev \
    libavcodec-dev \
    libavdevice-dev \
    libavfilter-dev \
    libavformat-dev \
    libavresample-dev \
    libavutil-dev \
    libpostproc-dev \
    libswresample-dev \
    libswscale-dev \
    libavcodec-extra \
    libopus-dev \
    libopencore-amrnb-dev \
    libopencore-amrwb-dev \
    libvo-amrwbenc-dev \
    portaudio19-dev \
    --assume-yes \
    --no-install-recommends

RUN wget --no-verbose "https://github.com/pjsip/pjproject/archive/$VERSION_PJSIP.tar.gz" -O - | tar xfz -

WORKDIR pjproject-$VERSION_PJSIP

RUN ./configure \
      --enable-shared \
      --prefix=/install

RUN make dep \
    && make \
    && make install

WORKDIR pjsip-apps/src/swig
RUN make \
    && make install

COPY requirements.txt /requirements.txt
RUN pip install --prefix=/install -r /requirements.txt

FROM base AS final
ENV LD_LIBRARY_PATH=/usr/local/lib

RUN apt-get update \
    && apt-get install \
    libasound2 \
    libssl1.1 \
    libv4l-0 \
    libsdl2-2.0-0 \
    libsdl2-gfx-1.0-0 \
    libsdl2-image-2.0-0 \
    libsdl2-mixer-2.0-0 \
    libsdl2-net-2.0-0 \
    libsdl2-ttf-2.0-0 \
    libx264-148 \
    libavdevice57 \
    libavfilter-extra6 \
    libavformat57 \
    libavresample3 \
    libavutil55 \
    libpostproc54 \
    libswresample2 \
    libswscale4 \
    libavcodec-extra \
    libopus0 \
    libopencore-amrnb0 \
    libopencore-amrwb0 \
    libvo-amrwbenc0 \
    libportaudio2 \
    libportaudiocpp0 \
    --assume-yes \
    --no-install-recommends \
    && apt-get autoremove --purge \
    && apt-get clean

COPY --from=build /install /usr/local
COPY --from=build /root/.local/lib/python3.6/site-packages /root/.local/lib/python3.6/site-packages

RUN adduser root audio

RUN touch /var/lib/in.docker;\
    apt-get update && apt-get install -y curl bash software-properties-common ;\
    curl -sL https://deb.nodesource.com/setup_16.x | bash - ;\
    apt-get install -y nodejs gcc g++ make ;\
    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarnkey.gpg >/dev/null ;\
    echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | tee /etc/apt/sources.list.d/yarn.list ;\
    apt-get update && apt-get install yarn

RUN yarn global add \
        npm@7.21.0 \
        nodemon \
        pm2 \
        node-gyp ;\
        pm2 install pm2-server-monit
