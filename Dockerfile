# Dockerfile for providing buildozer
# Build with:
# docker build --tag=buildozer .
# In order to give the container access to your current working directory
# it must be mounted using the --volume option.
# Run with (e.g. `buildozer --version`):
# docker run --volume "$(pwd)":/home/user/hostcwd buildozer --version
# Or for interactive shell:
# docker run --volume "$(pwd)":/home/user/hostcwd --entrypoint /bin/bash -it --rm buildozer
FROM ubuntu:18.04

ENV USER="user"
ENV HOME_DIR="/home/${USER}"
ENV WORK_DIR="${HOME_DIR}/hostcwd" \
    PATH="${HOME_DIR}/.local/bin:${PATH}"

# configures locale
RUN apt update -qq > /dev/null && \
    apt install -qq --yes --no-install-recommends \
    locales && \
    locale-gen en_US.UTF-8 && \
    apt install -qq --yes mc openssh-client nano wget curl pkg-config autoconf automake libtool time aria2
ENV LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"

# installs system dependencies (required to setup all the tools)
RUN apt install -qq --yes --no-install-recommends \
    sudo python-pip python-setuptools file

# https://buildozer.readthedocs.io/en/latest/installation.html#android-on-ubuntu-18-04-64bit
RUN dpkg --add-architecture i386 && apt update -qq > /dev/null && \
	apt install -qq --yes --no-install-recommends \
	build-essential ccache git libncurses5:i386 libstdc++6:i386 libgtk2.0-0:i386 \
	libpangox-1.0-0:i386 libpangoxft-1.0-0:i386 libidn11:i386 python2.7 \
	python2.7-dev openjdk-8-jdk unzip zlib1g-dev zlib1g:i386

# prepares non root env
RUN useradd --create-home --shell /bin/bash ${USER}
# with sudo access and no password
RUN usermod -append --groups sudo ${USER}
RUN echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && chown user -R /home/user

USER ${USER}
WORKDIR ${WORK_DIR}

# installs buildozer and dependencies
RUN pip install --user Cython==0.28.6 buildozer==0.37 sh

ARG DOT_VERSION=0.1.1
ARG DOT_HASH=631ee3c4aa0779850a3158481361f23ef052eb4416f2dbf27d501763778960a2
ARG DOT_PATH=https://github.com/homdx/pydelhi_mobile/releases/download
ARG DOT_FILE=android-buildozer-home.tar.gz
ARG DOT_HASH2=3cd98a9574ef0c2eb56a5802fc2621f25997d37c6922113d0d0e25c1b311882d
ARG DOT_FILE2=dot-buldozer-py2.tar.gz
ARG DOT_FILE3=gradle-home.tar.gz 
ARG DOT_HASH3=4f252d994929e2159c4d35acf482c10f05f82f45287202086c2933693b8fa636

USER ${USER}

COPY . app

#Use SDK cache and prebuild Cython files
RUN  sudo chown user -R app/ \
  &&  set -ex \
  && cd ${HOME_DIR} && sudo time -p aria2c -x 5 ${DOT_PATH}/${DOT_VERSION}/${DOT_FILE} \
  && echo "${DOT_HASH}  ${DOT_FILE}" | sha256sum -c \
  && time -p tar -xf ${DOT_FILE} && sudo rm ${DOT_FILE} \
  && sudo time -p aria2c -x 5 ${DOT_PATH}/${DOT_VERSION}/${DOT_FILE3} \
  && echo "${DOT_HASH3}  ${DOT_FILE3}" | sha256sum -c \
  && time -p tar -xf ${DOT_FILE3} && sudo rm ${DOT_FILE3} \
  && cd ${WORK_DIR}/app && time -p aria2c -x 5 ${DOT_PATH}/${DOT_VERSION}/${DOT_FILE2} \
  && echo "${DOT_HASH2}  ${DOT_FILE2}" | sha256sum -c \
  && time -p tar -xf ${DOT_FILE2} && rm ${DOT_FILE2}

#Fist build and maked with this (commented) RUN command
#RUN cd ${WORK_DIR}/app && cp -vf buildozer.old buildozer.spec && echo "temporatory build api 21" && time -p buildozer android debug || echo rm -rf .buildozer \
#    && cd  ~/.buildozer/android/platform && rm -vf *.zip *.gz

RUN cd ${WORK_DIR}/app \
    && cp -vf buildozer.new buildozer.spec && echo "build api 27" && time -p buildozer android debug || cd  ~/.buildozer/android/platform && rm -vf *.zip *.tgz *.gz \ 
    && sudo cp /home/user/hostcwd/app/.buildozer/android/platform/build/dists/conference/build/outputs/apk/debug/*.apk ${WORK_DIR}

CMD tail -f /var/log/faillog

#ENTRYPOINT ["buildozer"]
