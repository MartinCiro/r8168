#!/bin/bash

# Configuración
DRIVER_URL="https://rtitwww.realtek.com/rtdrivers/cn/nic1/r8168-8.049.02.tar.bz2"
TEMP_DIR="$HOME/temp_r8168_install"
SERVICE_FILE="/etc/systemd/system/wol.service"

# Colores para mensajes
COLOR_PURPLE='\e[35m'
COLOR_RESET='\e[0m'
COLOR_RED='\e[31m'
COLOR_GREEN='\e[32m'

# Funciones de utilidad
error_exit() {
    echo -e "${COLOR_RED}[ERROR] $1${COLOR_RESET}" >&2
    exit 1
}

info_msg() {
    echo -e "${COLOR_PURPLE}[INFO] $1${COLOR_RESET}"
}

success_msg() {
    echo -e "${COLOR_GREEN}[SUCCESS] $1${COLOR_RESET}"
}

# Limpieza de archivos temporales
cleanup() {
    info_msg "Limpiando archivos temporales..."
    rm -rf "$TEMP_DIR" 2>/dev/null
    rm -f "$HOME/r8168"* "$HOME/Descargas/r8168"* 2>/dev/null
}

# Registrar limpieza al salir
trap cleanup EXIT

# Crear directorio temporal
mkdir -p "$TEMP_DIR" || error_exit "No se pudo crear directorio temporal"
cd "$TEMP_DIR" || error_exit "No se pudo acceder al directorio temporal"

# Descargar e instalar driver
info_msg "Descargando el driver..."
wget --no-check-certificate -q "$DRIVER_URL" || error_exit "Fallo al descargar el driver"

info_msg "Extrayendo archivos..."
tar -xjvf r8168*.tar.bz2 || error_exit "Fallo al extraer el archivo"

info_msg "Contenido del directorio:"
ls -l

info_msg "Ingrese el nombre de la carpeta recién creada:"
read -r folder_name

if [ ! -d "$folder_name" ]; then
    error_exit "La carpeta '$folder_name' no existe"
fi

cd "$folder_name" || error_exit "No se pudo acceder a la carpeta del driver"

info_msg "Instalando el driver..."
sudo bash autorun.sh || error_exit "Fallo en la instalación del driver"

# Configurar Wake-on-LAN
info_msg "Detectando interfaces de red..."
ip -brief address show | awk '{print $1}'

info_msg "Ingrese el nombre de la interfaz de red (ej: enpXsY):"
read -r interface

if ! ip link show "$interface" &>/dev/null; then
    error_exit "La interfaz '$interface' no existe"
fi

info_msg "Configurando Wake-on-LAN para $interface..."
sudo ethtool -i "$interface"
sudo ethtool -s "$interface" wol g || error_exit "Fallo al configurar WOL"

info_msg "Creando servicio systemd para WOL..."
sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Configure Wake On LAN

[Service]
Type=oneshot
ExecStart=/sbin/ethtool -s $interface wol g

[Install]
WantedBy=basic.target
EOF

sudo systemctl daemon-reload || error_exit "Fallo al recargar daemon"
sudo systemctl enable wol.service || error_exit "Fallo al habilitar servicio"
sudo systemctl start wol.service || error_exit "Fallo al iniciar servicio"

# Mostrar información MAC
info_msg "Direcciones MAC disponibles:"
ip -brief link show | awk '{print $1,$3}'

info_msg "Ingrese la dirección MAC del equipo:"
read -r mac_address

# Validar formato MAC básico
if [[ ! "$mac_address" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
    error_exit "Formato de MAC inválido. Use formato XX:XX:XX:XX:XX:XX"
fi

# Instalar wakeonlan
info_msg "Instalando wakeonlan..."
sudo apt-get update && sudo apt-get install -y wakeonlan || error_exit "Fallo al instalar wakeonlan"

success_msg "Instalación completada exitosamente!"
