FROM ubuntu:22.04

RUN apt-get update

RUN apt install -y gcc make cmake git
RUN apt-get install -y python3 pip vim

RUN mkdir -p /usr/src/app

WORKDIR /usr/src/app/

RUN git clone https://github.com/pavel-collab/CRC32-check-sum.git

WORKDIR /usr/src/app/CRC32-check-sum

RUN git submodule update --init --recursive
RUN mkdir build

WORKDIR /usr/src/app/CRC32-check-sum/build

RUN cmake .. && make