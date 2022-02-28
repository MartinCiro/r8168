#!/bin/bash
echo -e "\e[35m Instalando el driver \e[0m"
wget --no-check-certificate https://rtitwww.realtek.com/rtdrivers/cn/nic1/r8168-8.049.02.tar.bz2
tar -xjvf r8168*
ls
echo -e "\e[35m Pegue el nombre de la carpeta nueva \e[0m"
read nm
cd $HOME/r8168/$nm
sudo bash autorun.sh

ip add | grep ": "
echo -e "\e[35m Escriba aquí el (enp...) \e[0m"
read enp
ethtool -i $enp
sudo ethtool -s $enp wol g
sudo touch /etc/systemd/system/wol.service
sudo echo "[Unit]
Description=Configure Wake On LAN

[Service]
Type=oneshot
ExecStart=/sbin/ethtool -s $enp wol g

[Install]
WantedBy=basic.target" >> /etc/systemd/system/wol.service

sudo systemctl daemon-reload
sudo systemctl enable wol.service
sudo systemctl start wol.service
echo -e "\e[35m Ubique link/ether Numero MAC \e[0m"
ip a
echo -e "\e[35m Pegue el MAC del equipo aquí: \e[0m"
read Mac
echo -e "\e[35m Instalando WOL \e[0m"
sudo apt install wakeonlan -y
rm -fr r*
rm -fr $HOME/r8168*
rm -fr $HOME/Descargas/r*
rm $HOME/Descargas/Iwol
#Eliminar desde el home
rm $HOME/Iwol
rm -fr $HOME/r*

