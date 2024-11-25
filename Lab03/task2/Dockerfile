FROM python:3.11

RUN apt update
RUN apt install -y vim

RUN pip install Flask==2.3.2
RUN pip install psycopg2==2.9.6

RUN mkdir /app

COPY ./app /app

WORKDIR /app