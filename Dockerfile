FROM debian:9

ENV APP_HOME /ekylibre
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

RUN apt-get update -qq && apt-get install -yf \
	curl \
	imagemagick \
	graphicsmagick \
	tesseract-ocr \
	tesseract-ocr-ara \
	tesseract-ocr-jpn \
	tesseract-ocr-fra \
	tesseract-ocr-eng \
	tesseract-ocr-spa \
	pdftk \
	libreoffice \
	poppler-utils \
	poppler-data \
	ghostscript \
	openjdk-8-jdk \
	libicu57 \
	redis-server \
	postgresql-9.6-postgis-2.3 \
	postgresql-contrib-9.6 \
	libcurl4-openssl-dev \
	libgeos-dev \
	libgeos++-dev \
	libproj-dev \
	libpq-dev \
	libxml2-dev \
	libxslt1-dev \
	zlib1g-dev \
	libicu-dev \
	libqtwebkit-dev \
	build-essential \
	&& apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

RUN \curl -sSL https://get.rvm.io | bash -s stable --ruby

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

ENV BUNDLE_PATH /bundle
ENV GEM_PATH /bundle
ENV GEM_HOME /bundle

ADD . $APP_HOME

#RUN /bin/bash -l -c "gem install bundler"
RUN gem install bundler

COPY Gemfile ./Gemfile
COPY Procfile ./Procfile

#RUN /bin/bash -l -c "bundle install"
RUN bundle install

#RUN /bin/bash -l -c "gem install foreman"
RUN gem install foreman

WORKDIR /app
COPY . ./
CMD ["bin/run-dev.sh"]
#RUN /bin/bash -l -c "foreman s"
