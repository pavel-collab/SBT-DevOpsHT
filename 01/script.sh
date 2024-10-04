#!/bin/bash

# Первая строчка -- путь к интерпритатору, через который будет выполняться скрипт

# Задаем переменные 
# В этом файле будем хранить pid запущенного процесса
PID_FILE="/run/my_demon.pid"
# В этот файл будем записывать логи
LOG_FILE="/tmp/my_demon.log"

# Аналог help
usage()
{
        echo "$0 (START|STOP|STATUS)"
}

# Функция остановки демона
stop()
{
	#TODO: использовать здесь функцию status, которая будет возвращать 0 или 1
        # Если существует pid файл, то убиваем процесс с номером из файла
        if [ -e ${PID_FILE} ]
        then
                _pid=$(cat ${PID_FILE}) # читаем pid процесса из файла в переменную
                kill $_pid # убиваем процесс
                rt=$?
                if [ "$rt" == "0" ]
                then
                        echo "Daemon stop" #TODO: продублировать сообщение в log
                else
                        echo "Error stop daemon"
                fi
        else
                echo "Daemon is not running"
        fi
}

status()
{
	if [ -e ${PID_FILE} ]
	then
		echo "Demon is running"
	else
		echo "Demon is not runnint"
	fi
}

start()
{
	echo "start"
}

# Точка входа в программу -- обработка аргумента командной строки
case $1 in
        "START")
                start
                ;;
        "STOP")
                stop
                ;;
	"STATUS")
		status
		;;
        *)
                usage
                ;;
esac
exit
