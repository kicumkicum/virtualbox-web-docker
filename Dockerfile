# Базовый образ
FROM ubuntu:20.04

### Base Layer ###

# Установка необходимых пакетов
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl wget unzip gcc make perl screen axel mc htop vim less

### VNC Layer ###

# Установка необходимых пакетов
# Установка зависимостей
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y x11vnc xvfb supervisor dbus-x11 websockify novnc wmctrl openbox

# Создаем папку для VNC и задаем пароль
RUN mkdir -p /root/.vnc && \
    echo "password" | x11vnc -storepasswd - /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

## Копируем конфиг Supervisor
#COPY etc/supervisor/conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
#COPY .config/openbox/rc.xml /root/.config/openbox/rc.xml

### VirtualBox Layer ###

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y kmod

# Скачивание и установка VirtualBox 6.1.12
COPY app/VirtualBox-6.1.12-139181-Linux_amd64.run /app/VirtualBox-6.1.12-139181-Linux_amd64.run
RUN chmod +x /app/VirtualBox-6.1.12-139181-Linux_amd64.run
RUN echo 'yes' | /app/VirtualBox-6.1.12-139181-Linux_amd64.run --nox11 || true
RUN rm /app/VirtualBox-6.1.12-139181-Linux_amd64.run

COPY app/Oracle_VM_VirtualBox_Extension_Pack-6.1.12.vbox-extpack /app/Oracle_VM_VirtualBox_Extension_Pack-6.1.12.vbox-extpack
RUN echo 'y' | /usr/bin/VBoxManage extpack install /app/Oracle_VM_VirtualBox_Extension_Pack-6.1.12.vbox-extpack ; true
RUN rm /app/Oracle_VM_VirtualBox_Extension_Pack-6.1.12.vbox-extpack

RUN VBoxManage setproperty websrvauthlibrary null

# Копируем конфиг Supervisor. Вернуть на место вверх после отладки
COPY etc/supervisor/conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY .config/openbox/rc.xml /root/.config/openbox/rc.xml
COPY app/bin/start-virtualbox.sh /app/bin/start-virtualbox.sh
RUN chmod +x /app/bin/start-virtualbox.sh

RUN mkdir -p /app/data
RUN mkdir -p /app/kernel-modules
RUN mkdir -p /app/inject-volumes
RUN mkdir -p /app/iso

# Открываем порты
EXPOSE 5900
EXPOSE 5901
EXPOSE 18083

# Запуск Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
