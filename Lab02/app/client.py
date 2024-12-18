from time import sleep
import socket

PORT = 8000

with open('ip', 'r') as f:
    # читаем ip сервера из файла и исключаем '\n'
    MY_IP = f.read()[:-1]

for i in range(1000):
    sct = socket.socket(socket.AF_INET, socket.SOCK_STREAM, socket.IPPROTO_TCP)
    sct.connect((MY_IP, PORT))

    try:
        sct.sendall(b'GET / HTTP/1.1\r\nHost: mipt.ru\r\nConnection: close\r\n\r\n')
        sct.shutdown(socket.SHUT_WR)
        reply = b''
        while True:
            buf = sct.recv(4096)
            if (len(buf) == 0):
                break
            reply += buf

        print(reply.decode('utf-8'))
    except KeyboardInterrupt:
        sct.close()

    sleep(5)