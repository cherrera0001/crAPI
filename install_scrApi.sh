#!/bin/bash

# Script de instalación y despliegue para OWASP crAPI en Ubuntu WSL
# Este script instala Docker y Docker Compose, descarga el archivo docker-compose.yml,
# y despliega los contenedores de OWASP crAPI en un entorno local.

# Ruta del directorio de instalación (directorio actual)
INSTALL_DIR="$(pwd)"

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" &> /dev/null
}

# Verifica y ajusta permisos de escritura en el directorio
check_permissions() {
    if [ ! -w "$INSTALL_DIR" ]; then
        echo "El directorio $INSTALL_DIR no tiene permisos de escritura. Ajustando permisos..."
        sudo chmod u+w "$INSTALL_DIR" || { echo "Error: No se pudo ajustar los permisos."; exit 1; }
    fi
}

# Instala Docker si no está instalado
install_docker() {
    echo "Instalando Docker..."
    sudo apt update
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
}

# Instala Docker Compose si no está instalado o si es una versión anterior a la requerida
install_docker_compose() {
    echo "Instalando Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
}

# Verificar Docker
if command_exists docker; then
    echo "Docker ya está instalado."
else
    install_docker
fi

# Verificar Docker Compose
if command_exists docker-compose; then
    # Verificar versión de Docker Compose
    DC_VERSION=$(docker-compose --version | awk '{print $3}' | sed 's/,//')
    if [[ "$(printf '%s\n' "1.27.0" "$DC_VERSION" | sort -V | head -n1)" != "1.27.0" ]]; then
        echo "Actualizando Docker Compose a la versión 1.27.0 o superior."
        install_docker_compose
    else
        echo "Docker Compose ya está en la versión requerida."
    fi
else
    install_docker_compose
fi

# Verificar permisos del directorio
check_permissions

# Descargar archivo docker-compose.yml
echo "Descargando archivo docker-compose.yml..."
curl -o docker-compose.yml https://raw.githubusercontent.com/OWASP/crAPI/main/deploy/docker/docker-compose.yml

# Descargar imágenes de Docker necesarias para OWASP crAPI
echo "Descargando imágenes de Docker..."
docker-compose pull

# Iniciar contenedores de OWASP crAPI en segundo plano
echo "Iniciando contenedores de Docker..."
docker-compose -f docker-compose.yml --compatibility up -d

# Mensaje de finalización y URLs de acceso
echo "Instalación y despliegue de OWASP crAPI completado. Puedes acceder en http://localhost:8888."
echo "Para revisar los correos, visita http://localhost:8025."
