# E-Tablet - Versión Demo

Sistema basico de tablet para FiveM QB/ESX 

## FOTOS DE LA TABLET 

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/8b802233-6ee5-4b80-8972-703c43b1fd00" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/d9f78b1b-14a6-490f-ae39-a891e08d182e" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/3c4c6117-f8b4-43ee-a7d6-92fd1a111050" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/15f83c95-3ab9-4174-82f9-dbebb5231e16" />


## ✨ Características

- 🔄 **Multi-Framework**: Compatible con ESX y QBCore
- 📱 **Aplicaciones Incluidas**:
  - 🏠 **Home**: Dashboard con información del jugador, estadísticas y servicios activos
  - 💰 **Banco**: Gestión completa de transacciones bancarias (depósitos, retiros, transferencias)
  - 📄 **Facturas**: Sistema de facturas pendientes con opción de pago
- 🔊 **Efectos de Sonido**: Sonidos para apertura, cierre, cambio de pestaña y clics

## 📋 Requisitos

- [oxmysql](https://github.com/overextended/oxmysql) (Obligatorio)
- ESX Legacy o QBCore Framework
- MySQL/MariaDB

## 🚀 Instalación

1. Descarga o clona el repositorio en tu carpeta `resources`:

```bash
cd resources
git clone https://github.com/em4nu3i69dll/e-tablet.git
```

2. Asegúrate de tener `oxmysql` instalado y configurado.

3. Agrega el recurso a tu `server.cfg`:

```cfg
ensure e-tablet
```

4. Reinicia el servidor o ejecuta:

```
restart e-tablet
```

## ⚙️ Configuración

Edita el archivo `shared/configuracion_tablet.lua`:


### Framework

- **`auto`**: Detecta automáticamente si estás usando ESX o QBCore
- **`esx`**: Fuerza el uso de ESX
- **`qb`**: Fuerza el uso de QBCore

## 🎮 Uso

### Comandos

- **`/tablet`** o **`/e-tablet`**: Abre/cierra la tablet
- **`F10`**: Tecla por defecto para abrir la tablet
- **`ESC`**: Cierra la tablet

## 🔧 Compatibilidad

### ESX
- Compatible con ESX Legacy
- Utiliza `xPlayer.getAccount('bank').money` para el banco
- Utiliza `xPlayer.getAccount('money').money` para efectivo
- Sistema de facturas compatible con `billing` de ESX

### QBCore
- Compatible con QBCore Framework
- Utiliza `PlayerData.money.bank` para el banco
- Utiliza `PlayerData.money.cash` para efectivo
- Sistema de facturas compatible con `qb-billing` de QBCore

## 📄 Licencia

Este proyecto esta libre para que lo utilicen de la forma que mas les guste, son libres de modificarlo y subirlo las veces que quieran a donde ustedes quieran siempre y cuando den los creditos. 

## 👤 Autor

**EM4NU3L69dll**
- Website: https://em4nu3l69dll.dev/
- GitHub: https://github.com/em4nu3i69dll

⭐ Si te gusta este recurso, no olvides darle una estrella

