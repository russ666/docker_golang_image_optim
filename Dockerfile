FROM golang:alpine

ENV JPEGOPTIM_VERSION=1.4.4 \
  PNGCRUSH_VERSION=1.8.10 \
  ZOPFLI_VERSION=1.0.1 \
  ADVANCECOMP_VERSION=1.23 \
  JHEAD_VERSION=3.00 \
  GIFSICLE_VERSION=1.88 \
  OPTIPNG_VERSION=0.7.6 \
  PNGQUANT_VERSION=2.8.2 \
  JPEGARCHIVE_VERSION=2.1.1 \
  MOZJPEG_VERSION=3.1 \
  IJG_VERSION=9a \
  PNGOUT_VERSION=20150319

# This step installs all external utilities, leaving only the
# compiled/installed binaries behind in order minimize the
# footprint of the image layer.
RUN apk update && apk add \

  # runtime dependencies

  # advcomp (libstdc++.so, libgcc_s.so)
  libstdc++ \

  # jpegoptim (libjpeg.so)
  libjpeg-turbo \

  # pngquant
  libpng \

  # svgo
  nodejs \

  # image_optim
  ruby \

  # build dependencies
  && apk add --virtual build-dependencies \
  build-base \

  # jpegoptim
  libjpeg-turbo-dev \

  # advancecomp
  zlib-dev \

  # pngquant
  bash libpng-dev \

  # mozjpeg
  pkgconfig autoconf automake libtool nasm \

  # utils
  curl \

  # image_optim
  ruby-irb

# advancecomp
RUN \
  curl -L -O https://github.com/amadvance/advancecomp/releases/download/v$ADVANCECOMP_VERSION/advancecomp-$ADVANCECOMP_VERSION.tar.gz \
  && tar zxf advancecomp-$ADVANCECOMP_VERSION.tar.gz \
  && cd advancecomp-$ADVANCECOMP_VERSION \
  && ./configure && make && make install
  # gifsicle
RUN \
  curl -O https://www.lcdf.org/gifsicle/gifsicle-$GIFSICLE_VERSION.tar.gz \
  && tar zxf gifsicle-$GIFSICLE_VERSION.tar.gz \
  && cd gifsicle-$GIFSICLE_VERSION \
  && ./configure && make && make install

# jhead
RUN \
  curl -O http://www.sentex.net/~mwandel/jhead/jhead-$JHEAD_VERSION.tar.gz \
  && tar zxf jhead-$JHEAD_VERSION.tar.gz \
  && cd jhead-$JHEAD_VERSION \
  && make && make install

# jpegoptim
RUN \
  curl -O http://www.kokkonen.net/tjko/src/jpegoptim-$JPEGOPTIM_VERSION.tar.gz \
  && tar zxf jpegoptim-$JPEGOPTIM_VERSION.tar.gz \
  && cd jpegoptim-$JPEGOPTIM_VERSION \
  && ./configure && make && make install

# jpeg-recompress (from jpeg-archive along with mozjpeg dependency)
RUN \
  curl -L -O https://github.com/mozilla/mozjpeg/archive/v$MOZJPEG_VERSION.tar.gz \
  && tar zxf v$MOZJPEG_VERSION.tar.gz \
  && cd mozjpeg-$MOZJPEG_VERSION \
  && autoreconf -fiv && ./configure && make && make install
RUN \
  curl -L -O https://github.com/danielgtaylor/jpeg-archive/archive/$JPEGARCHIVE_VERSION.tar.gz \
  && tar zxf $JPEGARCHIVE_VERSION.tar.gz \
  && cd jpeg-archive-$JPEGARCHIVE_VERSION \
  && make && make install

# jpegtran (from Independent JPEG Group)
RUN \
  curl -O http://www.ijg.org/files/jpegsrc.v$IJG_VERSION.tar.gz \
  && tar zxf jpegsrc.v$IJG_VERSION.tar.gz \
  && cd jpeg-$IJG_VERSION \
  && ./configure && make && make install

# optipng
RUN \
  curl -L -O http://downloads.sourceforge.net/project/optipng/OptiPNG/optipng-$OPTIPNG_VERSION/optipng-$OPTIPNG_VERSION.tar.gz \
  && tar zxf optipng-$OPTIPNG_VERSION.tar.gz \
  && cd optipng-$OPTIPNG_VERSION \
  && ./configure && make && make install

# pngcrush
RUN \
  curl -L -O http://downloads.sourceforge.net/project/pmt/pngcrush/$PNGCRUSH_VERSION/pngcrush-$PNGCRUSH_VERSION.tar.gz \
  && tar zxf pngcrush-$PNGCRUSH_VERSION.tar.gz \
  && cd pngcrush-$PNGCRUSH_VERSION \
  && make && cp -f pngcrush /usr/local/bin

# pngout (binary distrib)
RUN \
  curl -O http://static.jonof.id.au/dl/kenutils/pngout-$PNGOUT_VERSION-linux-static.tar.gz \
  && tar zxf pngout-$PNGOUT_VERSION-linux-static.tar.gz \
  && cd pngout-$PNGOUT_VERSION-linux-static \
  && cp -f x86_64/pngout-static /usr/local/bin/pngout

# pngquant
RUN \
  curl -L -O https://github.com/pornel/pngquant/archive/$PNGQUANT_VERSION.tar.gz \
  && curl -L -o $PNGQUANT_VERSION-lib.tar.gz -O https://github.com/ImageOptim/libimagequant/archive/$PNGQUANT_VERSION.tar.gz \
  && tar xzf $PNGQUANT_VERSION.tar.gz \
  && tar xzf $PNGQUANT_VERSION-lib.tar.gz \
  && cd libimagequant-$PNGQUANT_VERSION \
  && ./configure && make \
  && cd .. \
  && cp -rf libimagequant-$PNGQUANT_VERSION pngquant-$PNGQUANT_VERSION/lib \
  && cd pngquant-$PNGQUANT_VERSION \
  && ./configure && make && make install

# svgo
RUN npm install -g svgo

# image_optim
RUN \
  echo -e 'install: --no-document\nupdate: --no-document' > "$HOME/.gemrc" \
  && gem install --no-document image_optim

# cleanup
RUN \
  rm -rf /tmp/* \
  && apk del build-dependencies
