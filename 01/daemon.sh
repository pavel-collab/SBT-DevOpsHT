#!/bin/bash

# Первая строчка -- путь к интерпритатору, через который будет выполняться скрипт

# Задаем переменные 
# В этом файле будем хранить pid запущенного процесса
PID_FILE="/run/my_daemon.pid"
# В этот файл будем записывать логи
LOG_FILE="/tmp/my_daemon.log"
# В этот файл будем записывать логи с ошибками
ERR_LOG_FILE="/tmp/my_daemon_err.log"

# путь для файла .csv
CSV_PATH="/tmp"

# В этот файл будем записывать отчет демона
INFO_CSV=""
# при запуске скрипта будем фиксировать дату, это поможет нма понять, когда надо создавать новый .csv файл
DATE=$(date +"%D")

# Период обновления инфорации
PERIOD="10s"

#? Не знаю, почему, но парсинг аргументов не работает после того как мы распарсили $1
#? вероятнее всего getopts начинает парсинг с самого первого аргумента $1 и не может его распознать
#? но без START|STOP|STATUS все работает
# function check_arg(){
# 	if [[ $2 == -* ]]; then 
# 		echo "Option $1 requires an argument"
# 		exit 1
# 	fi
# }

# parse_params()
# {
# 	while getopts :c:p: OPTION; do
# 		case "$OPTION" in
# 			c) 
# 				echo "new csv path is $OPTARG"
# 				check_arg "-c" "$OPTARG"
# 				CSV_PATH=$OPTARG
# 				;;
# 			p)
# 				echo "new periode is $OPTARG"
# 				check_arg "-p" "$OPTARG"
# 				PERIOD=$OPTARG
# 				;;
# 			:)
# 				echo "Option -$OPTARG requires an argument (getopts)"
# 				exit 1
# 				;;
# 			*) 
# 				echo "unexpected option"
# 				exit 1
# 				;;
# 		esac
# 	done
# }

create_csv_file()
{	
	INFO_CSV="${CSV_PATH}/$(date | sed 's/ /_/g').csv"
	echo "Date,Disk,Size,Used,Free,Inode Size,Inode Used,Inode Free" > $INFO_CSV
	_log "Created file ${INFO_CSV}"
}

# Аналог help
usage()
{
    echo "$0 (START|STOP|STATUS)"
}

# Функция остановки демона
stop()
{
	# Проверяем запуск от рута
    if [ $UID -ne 0 ]; then
        echo "Root privileges required"
        exit 0
    fi

    # Если существует pid файл, то убиваем процесс с номером из файла
    if [ -e ${PID_FILE} ]
    then
        _pid=$(cat ${PID_FILE}) # читаем pid процесса из файла в переменную
        kill $_pid # убиваем процесс
        rt=$? #! $? -- код возврата последнего процесса (функции или скрипта)  (см. https://ru.wikipedia.org/wiki/Bash)
        if [ "$rt" == "0" ]
        then
                echo "Daemon stop"
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
    ts=`date +"%b %d %Y %H:%M:%S"`
    hn=`cat /etc/hostname`
    echo "$ts $hn $*" #! $* -- все аргументы функции в одной строке (см. https://ru.wikipedia.org/wiki/Bash)
}

# функция создает файлы для логирования
create_log_files()
{
	if [ -e ${LOG_FILE} ]; then
		cat ${LOG_FILE} >> ${LOG_FILE}.prev
		rm -f ${LOG_FILE} # флаг -f -- тихое удаление без вопросов
	fi
	touch ${LOG_FILE}
	
	if [ -e ${ERR_LOG_FILE} ]; then
		cat ${ERR_LOG_FILE} >> ${ERR_LOG_FILE}.prev
		rm -f ${ERR_LOG_FILE}
	fi
	touch ${ERR_LOG_FILE}
}

# Функция происзодит отчистку при завершении демона
# Удаляется файл с PID демона
# Также, удаляются файлы с логами, а их содержимое дублируется в файлы с постфиксом .prev, лежащие по тому же пути
cleanup()
{
	rm -f ${PID_FILE} 
	cat ${LOG_FILE} >> ${LOG_FILE}.prev
	cat ${ERR_LOG_FILE} >> ${ERR_LOG_FILE}.prev
	rm -f ${LOG_FILE}; rm -f ${ERR_LOG_FILE}
}

# Фунция запуска демона
start()
{
	# Проверяем запуск от рута
	# Это нужно, чтобы создать файл с pid по пути /run
	if [ $UID -ne 0 ]; then #! UID (идентификатор) текущего пользователя, в соответствии с /etc/passwd, UID рута всегда 0 (см. https://www.opennet.ru/docs/RUS/bash_scripting_guide/c3270.html#UIDREF)
    	echo "Root privileges required"
    	exit 0
    fi

	echo "start"
	# Проверка на вторую копию (если вдруг демон уже запущен)
    if [ -e ${PID_FILE} ]; then
    	_pid=( `cat ${PID_FILE}` )
    	if [ -e "/proc/${_pid}" ]; then
        	echo "Daemon already running with pid = $_pid"
        	exit 0
    	fi
    fi

	# создаем файлы с логами
	create_log_files
	create_csv_file # создаем новый файл

	# получаем список файловых систем
	#! df -- выводит список файловый систем
	#! awk '{print $1}' -- оставляет только 1й столбей
	#! sed '1d' -- удаляет первую сточку (шапку)
	disks=$(df --exclude-type=tmpfs --exclude-type=efivarfs | awk '{print $1}' | sed '1d')

	# Демонизация процесса
    cd /
   	exec > ${LOG_FILE} #! Перенаправляем стандартный вывод процесса в LOG_FILE
    exec 2> ${ERR_LOG_FILE} #! Перенаправляем стандарный поток ошибок в лог с ошибками
    exec < /dev/null #! Стандартный поток ввода нам не нужен, поэтому перенаправляем его в пустоту

	# Здесь происходит порождение Потомка.
	( #! область в круглых скобках -- код, который будет выполнен процессом-потомком
		
		#! Вешаем sighandler на событие, которое убивает наш процесс
		# При убийстве процесса чистим файлы, завершаем процесс
		trap  "{ cleanup; _log daemon stop; exit 255; }" TERM INT EXIT 
		
		_log "Daemon started"
		# Пишем номер pid процесса в файл, на всякий случай
		_log "process PID is" $$

		# Основной цикл
		while [ 1 ] 
		do
			# При переходе через сутки создаем новый .csv файл и начинаем писать в него
			cur_date=$(date +"%D")
			if [ $cur_date != $DATE ]; then
				create_csv_file # создаем новый файл
				DATE=${cur_date} # присваиваем новое значение даты
				_log "New .csv file created -- ${INFO_CSV}"
			fi

			for disk in ${disks}; do				
				date=$(date) #! Имеет значение какие скобки использовать {} или (). () -- для комманд и функций, {} -- для переменных

				# Получаем необходимую информацию о ФС
				#! sed 's/,/./g' заменяет все запятые на точки, это делается потому, что в выводе df дробная часть числа отделяется запятой,
				#! а в .csv файлах точкой, так как запятая там является разделителем столбцов
        		size_info=$(df ${disk} -h | sed '1d' | awk '{print $2, $3, $4}' | sed 's/,/./g' | sed 's/ /,/g') 
        		inode_info=$(df ${disk} -hi | sed '1d' | awk '{print $2, $3, $4}' | sed 's/,/./g' | sed 's/ /,/g')
        		disk_info="${date},${disk},${size_info},${inode_info}"

				# Проверяем количество свободного места на диске (в MB)
				percent_used_disk_space=$(df ${disk} -h | sed '1d' | awk '{print $5}' | sed 's/%//')
				if [ ${percent_used_disk_space} -gt 80 ]; then
					_log There are too little space on disk ${disk}
				fi

				echo ${disk_info} >> ${INFO_CSV}
			done

			sleep $PERIOD
		done
	)& #! & в конце означает, что процесс выполняется в фоне
	
	# Пишем pid потомка в файл
	echo $! > ${PID_FILE} #! в данном случае $! -- pid последнего запущенного процесса (см. https://ru.wikipedia.org/wiki/Bash)
}

# Точка входа в программу -- обработка аргумента командной строки
case $1 in
    "START")
		#? Не знаю, почему, но парсинг аргументов не работает после того как мы распарсили $1
		# parse_params
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
