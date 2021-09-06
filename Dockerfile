FROM ubuntu:16.04
MAINTAINER Jimmy Song <http://github.com/jimmysong>

# Install LXDE, Twisted, SWIG and Qt
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server x11-apps lxde-core lxterminal curl gnupg g++ libcrypto++-dev swig python-dev python-twisted libqtcore4 libqt4-dev python-qt4 pyqt4-dev-tools python-psutil xdg-utils pkg-config build-essential autoconf libtool rsync

# Download armory
RUN mkdir /armory
WORKDIR /armory
ENV ARMORY_VERSION 0.96.3
RUN curl -SLO "https://github.com/goatpig/BitcoinArmory/releases/download/v${ARMORY_VERSION}/armory_${ARMORY_VERSION}-src.tar.gz"
RUN curl -SLO "https://github.com/goatpig/BitcoinArmory/releases/download/v${ARMORY_VERSION}/sha256sum.txt.asc"

# Verify and unpack download
COPY goatpig-signing-key.asc /armory
RUN gpg --import goatpig-signing-key.asc \
 && gpg --verify --trust-model=always sha256sum.txt.asc \
 && gpg --decrypt --output sha256sum.txt sha256sum.txt.asc \
 && grep "armory_${ARMORY_VERSION}-src.tar.gz" sha256sum.txt | sha256sum -c - \
 && tar xzf "armory_${ARMORY_VERSION}-src.tar.gz" \
 && rm "armory_${ARMORY_VERSION}-src.tar.gz" sha256sum.txt.asc sha256sum.txt

# build and install
ENV SRC_DIR /armory/armory_${ARMORY_VERSION}-src
WORKDIR SRC_DIR
RUN ./autogen.sh && ./configure && make && make install

WORKDIR /armory
RUN rm -rf SRC_DIR
RUN ln -s /armory /root/.armory
RUN mkdir /root/.ssh \
 && chmod 700 /root/.ssh \
 && mkdir /var/run/sshd \
 && perl -p -i -e "s/\#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config

# Expose SSH port for X11 forwarding
ENV DISPLAY :0
EXPOSE 22

COPY run.sh /opt
CMD ["/opt/run.sh"]
