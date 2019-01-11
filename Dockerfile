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
    apt install -qq --yes mc openssh-client nano wget curl pkg-config autoconf automake libtool time aria2 libffi-dev libssl-dev
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

ARG DOT_VERSION=0.1.3
ARG DOT_HASH=f114a09ac02b9291a1d7b609710801e135d3cf327939ba5bf7273228c3c2e866
ARG DOT_PATH=https://github.com/homdx/pydelhi_mobile/releases/download
ARG DOT_FILE=python-gradle2.tar.gz

ENV SDK_TOOLS="sdk-tools-linux-4333796.zip"
ENV NDK_DL="https://dl.google.com/android/repository/android-ndk-r17c-linux-x86_64.zip"
ENV NDKVER=r17c
ENV NDKDIR=/ndk/
ENV NDKAPI=21
ENV ANDROIDAPI=28
ENV PIP=pip3

USER root

# Install base packages
RUN apt update && apt install -y zip python3 python-pip python python3-virtualenv python-virtualenv python3-pip curl wget lbzip2 bsdtar && dpkg --add-architecture i386 && apt update && apt install -y build-essential libstdc++6:i386 zlib1g-dev zlib1g:i386 openjdk-8-jdk libncurses5:i386 && apt install -y libtool automake autoconf unzip pkg-config git ant gradle rsync python3.7-venv

# Install Android SDK:
RUN mkdir /sdk-install/ && chown user /sdk-install

USER ${USER}

RUN cd /sdk-install && wget --quiet https://dl.google.com/android/repository/${SDK_TOOLS}

RUN cd /sdk-install && unzip ./sdk-tools-*.zip && chmod +x ./tools//bin/sdkmanager
RUN yes | /sdk-install/tools/bin/sdkmanager --licenses
RUN /sdk-install/tools/bin/sdkmanager --update
RUN /sdk-install/tools/bin/sdkmanager "platform-tools" "platforms;android-28" "build-tools;28.0.3"
# Obtain Android NDK:
RUN mkdir -p /tmp/ndk/ && cd /tmp/ndk/ && wget --quiet ${NDK_DL} && unzip -q android-ndk*.zip && sudo mv android-*/ /ndk/

USER root

# Final command line preparation:
RUN echo '#!/usr/bin/python3\n\
import json\n\
import os\n\
print("echo \"\"")\n\
print("echo \"To build a kivy demo app, use this command:\"")\n\
if os.environ["PIP"] == "pip2":\n\
    print("echo \"cd ~/testapp-sdl2-keyboard && p4a apk --arch=armeabi-v7a --name test --package com.example.test --version 1 --requirements=kivy,python2 --private .\"")\n\
    print("shopt -s expand_aliases")\n\
    print("alias testbuild=\"cd ~/testapp-sdl2-keyboard && p4a apk --arch=armeabi-v7a --name test --package com.example.test --version 1 --requirements=kivy,python2 --private . && cp *.apk ~/output\"")\n\
    print("alias testbuild_webview=\"cd ~/testapp-webview-flask && p4a apk --arch=armeabi-v7a --name test --package com.example.test --version 1 --bootstrap webview --requirements=python2,flask --private . && cp *.apk ~/output\"")\n\
    print("alias testbuild_service_only=\"cd ~/testapp-service_only-nogui && p4a apk --arch=armeabi-v7a --name test --package com.example.test --version 1 --bootstrap service_only --requirements=pyjnius,python2 --private . && cp *.apk ~/output\"")\n\
else:\n\
    print("echo \"cd ~/testapp-sdl2-keyboard && p4a apk --arch=armeabi-v7a --name test --package com.example.test --version 1 --requirements=kivy,python3 --private .\"")\n\
    print("shopt -s expand_aliases")\n\
    print("alias testbuild=\"cd ~/testapp-sdl2-keyboard && p4a apk --arch=armeabi-v7a --name test --package com.example.test --version 1 --requirements=kivy,python3 --private . && cp *.apk ~/output\"")\n\
    print("alias testbuild_webview=\"cd ~/testapp-webview-flask && p4a apk --arch=armeabi-v7a --name test --package com.example.test --version 1 --bootstrap webview --requirements=python3,flask --private . && cp *.apk ~/output\"")\n\
    print("alias testbuild_service_only=\"cd ~/testapp-service_only-nogui && p4a apk --arch=armeabi-v7a --name test --package com.example.test --version 1 --bootstrap service_only --requirements=pyjnius,python3 --private . && cp *.apk ~/output\"")\n\
launch_cmd="{LAUNCH_CMD} "\n\
print("export ANDROIDAP='$ANDROIDAPI'" +\n\
    " ANDROIDNDKVER='$NDKVER'" +\n\
    " NDKAPI='$NDKAPI'" +\n\
    " GRADLE_OPTS=\"-Xms1724m -Xmx5048m -Dorg.gradle.jvmargs='"'"'-Xms1724m -Xmx5048m'"'"'\""+\n\
    " JAVA_OPTS=\"-Xms1724m -Xmx5048m\"" +\n\
    " ANDROIDSDK=/sdk-install/ ANDROIDNDK=\"'$NDKDIR'\"")\n\
print(launch_cmd)' > /cmdline.py && chmod +x /cmdline.py

USER ${USER}

RUN pip3 list

RUN sudo apt update && echo sudo apt install -y libwebkit2gtk-4.0-dev gtk+-3.0

USER ${USER}

#Python2 Python3 cache and gradle cache files

ARG DISABLECACHE

RUN set -ex && \
    if [ -z "$DISABLECACHE" ] ; \
    then echo 'Now enable Cached files for Python2and3 and .gradle files. If you not need cache build with: --build-arg DISABLECACHE=something'; \
    set -ex ; \
    cd ${HOME_DIR} ; sudo time -p aria2c -x 5 ${DOT_PATH}/${DOT_VERSION}/${DOT_FILE} ; \
    echo "${DOT_HASH}  ${DOT_FILE}" | sha256sum -c ; \
    time -p sudo tar -xf ${DOT_FILE} ; sudo rm ${DOT_FILE} ; \
    cd ${WORK_DIR}/p4acache/python-for-android ; \
    python3 setup.py build ; sudo python3 setup.py install ; pip3 install Cython ; pip3 list ; \
    else echo Cache are disabled = $DISABLECACHE; \
    # Build full version \
    cd ${WORK_DIR} ; sudo mkdir p4acache; sudo chown user p4acache; cd p4acache; git clone --single-branch -b master https://github.com/kivy/python-for-android ; \
    cd ${WORK_DIR}/p4acache/python-for-android ; \
    python3 setup.py build ; sudo python3 setup.py install ; pip3 install Cython ; pip3 list ; \
    echo build Full version; \
    fi

COPY . app


VOLUME /home/user/result

RUN echo Python3 FunCrash && sudo mkdir app2 && sudo chown user app2 && cd app2 && git clone https://github.com/homdx/funcrash && cd funcrash && git checkout test && cp -vf buildozer-python31.spec buildozer.spec \
&& patch -p0 <main-without-cred.patch \
&& ANDROIDAP=28 ANDROIDNDKVER=r17c NDKAPI=21 GRADLE_OPTS="-Xms1724m -Xmx5048m -Dorg.gradle.jvmargs='-Xms1724m -Xmx5048m'" JAVA_OPTS="-Xms1724m -Xmx5048m" ANDROIDSDK=/sdk-install/ ANDROIDNDK="/ndk/" p4a apk --arch=armeabi-v7a --name 'Fun Crash' --package com.example.test --version 1 --orientation=landscape --presplash=images/splashscreen01.png --icon=images/icon01.png --requirements=kivy,python3,paho-mqtt --private . \
&& sudo chmod 777 ${HOME_DIR}/result && cp -v /home/user/.local/share/python-for-android/dists/unnamed_dist_1/build/outputs/apk/debug/*debug.apk ${HOME_DIR}/result/py3-funcrash.apk

RUN echo Python3 PyDelhi && sudo chown user -R app/ && cd app && cp .p4a pydelhiconf/ && cd pydelhiconf && ANDROIDAP=28 ANDROIDNDKVER=r17c NDKAPI=21 GRADLE_OPTS="-Xms1724m -Xmx5048m -Dorg.gradle.jvmargs='-Xms1724m -Xmx5048m'" JAVA_OPTS="-Xms1724m -Xmx5048m" ANDROIDSDK=/sdk-install/ ANDROIDNDK="/ndk/"  p4a apk --private . && sudo cp '/home/user/.local/share/python-for-android/dists/unnamed_dist_2/build/outputs/apk/debug/unnamed_dist_2-debug.apk' ${HOME_DIR}/result/py3-pydelhi.apk

RUN echo Python2 PyDelhi && cd app && cp -vf p4a-py2 .p4a && cp -vf .p4a pydelhiconf/ && cd pydelhiconf && ANDROIDAP=28 ANDROIDNDKVER=r17c NDKAPI=21 GRADLE_OPTS="-Xms1724m -Xmx5048m -Dorg.gradle.jvmargs='-Xms1724m -Xmx5048m'" JAVA_OPTS="-Xms1724m -Xmx5048m" ANDROIDSDK=/sdk-install/ ANDROIDNDK="/ndk/" p4a apk --private . && sudo cp '/home/user/.local/share/python-for-android/dists/unnamed_dist_3/build/outputs/apk/debug/unnamed_dist_3-debug.apk' ${HOME_DIR}/result/py2-pydelhi.apk

CMD tail -f /var/log/faillog

#ENTRYPOINT ["buildozer"]
