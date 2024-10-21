#! /usr/bin/python3

# протокол udp -- каждая посылка это 1 пакет
import socket
from datetime import datetime

PORT = 7555

sct = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
# фиксируем локальный конец
sct.bind(('', PORT))

print('listening on port: %d' %PORT)
try:
    while True:
        data, adr_info = sct.recvfrom(4096)

        if (data.decode('utf-8') == 'get datetime'):
            reply = 'date, time : (%s)\n' %datetime.today()
            sct.sendto(reply.encode('utf-8'), adr_info)

except KeyboardInterrupt:
    print('\nend of listening')
    sct.close()