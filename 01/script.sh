#!/bin/bash

# Первая строчка -- путь к интерпритатору, через который будет выполняться скрипт

# Задаем переменные 
# В этом файле будем хранить pid запущенного процесса
PID_FILE="/run/my_demon.pid"
# В этот файл будем записывать логи
LOG_FILE="/tmp/my_demon.log"
# В этот файл будем записывать логи с ошибками
ERR_LOG_FILE="/tmp/my_demon_err.log"

# Аналог help
usage()
{
        echo "$0 (START|STOP|STATUS)"
}

# Функция остановки демона
stop()
{
	# Проверяем запуск от рута
        #TODO: вынести в отдельную функцию
        if [ $UID -ne 0 ]; then
                echo "Root privileges required"
                exit 0
        fi

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

# Функция логирования
_log()
{
    # Сдвигаем влево входные параметры
    #shift
    ts=`date +"%b %d %Y %H:%M:%S"`
    hn=`cat /etc/hostname`
    echo "$ts $hn $*" # $* -- все аргументы функции в одной строке (см. https://ru.wikipedia.org/wiki/Bash)
}

start()
{
	# Проверяем запуск от рута
	# Это нужно, чтобы создать файл с pid по пути /run
	#TODO: вынести в отдельную функцию
    	if [ $UID -ne 0 ]; then
        	echo "Root privileges required"
        	exit 0
    	fi

	echo "start" # DEBUG
	# Проверка на вторую копию
    	if [ -e ${PID_FILE} ]; then
        	_pid=( `cat ${PID_FILE}` )
        	if [ -e "/proc/${_pid}" ]; then
            		echo "Daemon already running with pid = $_pid"
            		exit 0
        	fi
    	fi

	touch ${LOG_FILE}
	touch ${ERR_LOG_FILE}

	# Демонизация процесса
    	cd /
   	exec > ${LOG_FILE} # Перенаправляем стандартный вывод процесса в LOG_FILE
    	exec 2> ${ERR_LOG_FILE} # Перенаправляем стандарный поток ошибок в лог с ошибками
    	exec < /dev/null # Стандартный поток ввода нам не нужен, поэтому перенаправляем его в пустоту
	
	# Здесь происходит порождение Потомка.
	( # область в круглых скобках -- код, который будет выполнен процессом-потомком
		
		# Не забываем удалять файл с номером процесса и файл очереди при выходе 
		#TODO: при прирывании процесса сделать так, чтобы он писал в лог о своей остановке
		#TODO: при остановке копировать лог в другой лог с постфиксом .prev
		trap  "{ rm -f ${PID_FILE}; exit 255; }" TERM INT EXIT 

		# Пишем номер pid процесса в файл, на всякий случай
		echo "$$" > ${LOG_FILE}
		
		_log "Daemon started"

		while [ 1 ] 
		do
			sleep 8
			echo "Check message" # так как вывод мы уже перенаправили, что сообщения пойдут в лог
		done
	)& # & в конце означает, что процесс выполняется в фоне
	
	# Пишем pid потомка в файл
	echo $! > ${PID_FILE} # в данном случае $! -- pid последнего запущенного процесса (см. https://ru.wikipedia.org/wiki/Bash)
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
