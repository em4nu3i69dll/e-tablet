# E-Tablet - Versión Demo

Sistema basico de tablet para FiveM QB/ESX 

## FOTOS DE LA TABLET 

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/50840d52-78dc-4ffd-a8bb-e27e67ca29f4" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/07edadf8-d1d4-4df8-b074-50bb2ea70eff" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/f46c01cc-36b5-48ce-adcb-61647f082848" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/2e1cfcbc-51a9-4301-9b6e-c6ce77adf474" />

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

⭐ Si te gusta este recurso, no olvides darle una estrella en GitHub!

