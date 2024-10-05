#!/bin/bash

# Первая строчка -- путь к интерпритатору, через который будет выполняться скрипт

# Задаем переменные 
# В этом файле будем хранить pid запущенного процесса
PID_FILE="/run/my_daemon.pid"
# В этот файл будем записывать логи
LOG_FILE="/tmp/my_daemon.log"
# В этот файл будем записывать логи с ошибками
ERR_LOG_FILE="/tmp/my_daemon_err.log"
# В этот файл будем записывать отчет демона
INFO_CSV="/tmp/info.csv" #TODO: генерация имени для файла
# Период обновления инфорации
PERIOD="10s"

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
		echo "daemon is running"
	else
		echo "daemon is not runnint"
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

create_info_file()
{
	if [ ! -e ${INFO_CSV} ]; then
		echo "Date,Disk,Size,Used,Free,Inode Size,Inode Used,Inode Free" > $INFO_CSV
	else
		echo "CSV file exists"
    fi
}

cleanup()
{
	rm -f ${PID_FILE} 
	cat ${LOG_FILE} >> ${LOG_FILE}.prev
	cat ${ERR_LOG_FILE} >> ${ERR_LOG_FILE}.prev
	rm -f ${LOG_FILE}; rm -f ${ERR_LOG_FILE}
}

start()
{
	# Проверяем запуск от рута
	# Это нужно, чтобы создать файл с pid по пути /run
	#TODO: вынести в отдельную функцию
	if [ $UID -ne 0 ]; then # UID (идентификатор) текущего пользователя, в соответствии с /etc/passwd, UID рута всегда 0 (см. https://www.opennet.ru/docs/RUS/bash_scripting_guide/c3270.html#UIDREF)
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

	#TODO: проверка на существование
	touch ${LOG_FILE}
	touch ${ERR_LOG_FILE}

	create_info_file

	disks=$(df --exclude-type=tmpfs --exclude-type=efivarfs | awk '{print $1}' | sed '1d')

	# Демонизация процесса
    cd /
   	exec > ${LOG_FILE} # Перенаправляем стандартный вывод процесса в LOG_FILE
    exec 2> ${ERR_LOG_FILE} # Перенаправляем стандарный поток ошибок в лог с ошибками
    exec < /dev/null # Стандартный поток ввода нам не нужен, поэтому перенаправляем его в пустоту
	
	# Здесь происходит порождение Потомка.
	( # область в круглых скобках -- код, который будет выполнен процессом-потомком
		
		# Вешаем sighandler на событие, которое убивает наш процесс
		# При убийстве процесса чистим файлы, завершаем процесс
		trap  "{ cleanup; _log daemon stop; exit 255; }" TERM INT EXIT 
		
		_log "Daemon started"
		# Пишем номер pid процесса в файл, на всякий случай
		_log "process PID is" $$

		while [ 1 ] 
		do
			for disk in ${disks}; do				
				date=$(date) # Имеет значение какие скобки использовать {} или (). () -- для комманд и функций, {} -- для переменных

        		size_info=$(df ${disk} -h | sed '1d' | awk '{print $2, $3, $4}' | sed 's/,/./g' | sed 's/ /,/g')
        		inode_info=$(df ${disk} -hi | sed '1d' | awk '{print $2, $3, $4}' | sed 's/,/./g' | sed 's/ /,/g')
        		result_str="${date},${disk},${size_info},${inode_info}"

				disk_info=${result_str}

				echo ${disk_info} >> ${INFO_CSV}
			done

			sleep $PERIOD
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
