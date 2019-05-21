FROM node:slim

MAINTAINER Minghe Huang <h.minghe@gmail.com>

# Install Git, needed to publish to GitHub
RUN apt-get update && apt-get install -y git ssh-client rsync --no-install-recommends && rm -r /var/lib/apt/lists/*

# Change timezone to China Standard Time
RUN echo "Asia/Shanghai" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

# Prepare work directory
RUN mkdir /hexo
WORKDIR /hexo

ADD blog /hexo
# Install Hexo
RUN npm install hexo-cli -g
RUN npm install
RUN hexo generate


EXPOSE 4000

CMD ["hexo", "server", "-i", "0.0.0.0"]
