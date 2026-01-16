if not Configuracion.Tablet or not Configuracion.Tablet.Habilitado then return end

local Framework = nil
local ESX = nil
local QBCore = nil
local DatosTest = {}

if Configuracion.Tablet.Framework == 'auto' then
    if GetResourceState('es_extended') == 'started' then
        Framework = 'esx'
        ESX = exports['es_extended']:getSharedObject()
    elseif GetResourceState('qb-core') == 'started' then
        Framework = 'qb'
        QBCore = exports['qb-core']:GetCoreObject()
    end
elseif Configuracion.Tablet.Framework == 'esx' then
    Framework = 'esx'
    ESX = exports['es_extended']:getSharedObject()
elseif Configuracion.Tablet.Framework == 'qb' then
    Framework = 'qb'
    QBCore = exports['qb-core']:GetCoreObject()
end

if not Framework then return end

local function ObtenerConteoTrabajo(nombreTrabajo)
    local conteo = 0
    if Framework == 'esx' then
        local xPlayers = ESX.GetPlayers()
        for i = 1, #xPlayers do
            local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
            if xPlayer and xPlayer.job.name == nombreTrabajo and xPlayer.job.grade >= 1 then
                conteo = conteo + 1
            end
        end
    else
        local jugadores = QBCore.Functions.GetQBPlayers()
        for _, jugador in pairs(jugadores) do
            if jugador.PlayerData.job.name == nombreTrabajo and jugador.PlayerData.job.onduty then
                conteo = conteo + 1
            end
        end
    end
    return conteo
end

RegisterNetEvent('e-tablet:obtenerDatosJugador', function()
    local src = source
    local datosJugador = {}
    if Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
        datosJugador = {
            ciudadano = xPlayer.identifier,
            nombre = xPlayer.getName(),
            fechaNacimiento = xPlayer.get('dateofbirth') or 'N/A',
            efectivo = xPlayer.getMoney(),
            banco = xPlayer.getAccount('bank').money,
            trabajo = xPlayer.job.label or 'Desempleado',
            grado = xPlayer.job.grade_label or 'N/A',
            telefono = xPlayer.get('phoneNumber') or 'N/A',
            id = src,
            policia = ObtenerConteoTrabajo('police'),
            ems = ObtenerConteoTrabajo('ambulance'),
            mecanico = ObtenerConteoTrabajo('mechanic'),
            taxi = ObtenerConteoTrabajo('taxi'),
            totalJugadores = #GetPlayers()
        }
    else
        local Jugador = QBCore.Functions.GetPlayer(src)
        if not Jugador then return end
        local datosJugadorQb = Jugador.PlayerData
        datosJugador = {
            ciudadano = datosJugadorQb.citizenid,
            nombre = datosJugadorQb.charinfo.firstname .. ' ' .. datosJugadorQb.charinfo.lastname,
            fechaNacimiento = datosJugadorQb.charinfo.birthdate or 'N/A',
            efectivo = datosJugadorQb.money.cash or 0,
            banco = datosJugadorQb.money.bank or 0,
            trabajo = datosJugadorQb.job.label or 'Desempleado',
            grado = datosJugadorQb.job.grade.name or 'N/A',
            telefono = datosJugadorQb.charinfo.phone or 'N/A',
            id = src,
            policia = ObtenerConteoTrabajo('police'),
            ems = ObtenerConteoTrabajo('ambulance'),
            mecanico = ObtenerConteoTrabajo('mechanic'),
            taxi = ObtenerConteoTrabajo('taxi'),
            totalJugadores = #GetPlayers()
        }
    end
    TriggerClientEvent('e-tablet:recibirDatosJugador', src, datosJugador)
end)

RegisterCommand('test', function(source)
    local src = source
    if src == 0 then return end
    
    DatosTest[src] = {
        transacciones = {
            {type = 'deposit', value = 5000, date = os.time(), sender_name = 'Sistema', receiver_name = 'Usuario'},
            {type = 'withdraw', value = 1200, date = os.time() - 3600, sender_name = 'Cajero Automático', receiver_name = 'Usuario'},
            {type = 'transfer', value = 25000, date = os.time() - 86400, sender_name = 'Inversiones Maze Bank', receiver_name = 'Usuario'},
            {type = 'transfer', value = 450, date = os.time() - 172800, sender_name = 'Usuario', receiver_name = '24/7 Store'},
            {type = 'deposit', value = 15000, date = os.time() - 259200, sender_name = 'Venta de Vehículo', receiver_name = 'Usuario'},
            {type = 'withdraw', value = 500, date = os.time() - 345600, sender_name = 'Cajero Express', receiver_name = 'Usuario'},
            {type = 'transfer', value = 8000, date = os.time() - 432000, sender_name = 'Nómina', receiver_name = 'Usuario'},
            {type = 'transfer', value = 200, date = os.time() - 518400, sender_name = 'Usuario', receiver_name = 'Donny Burger'},
            {type = 'deposit', value = 1200, date = os.time() - 604800, sender_name = 'Reembolso Seguro', receiver_name = 'Usuario'},
            {type = 'withdraw', value = 3000, date = os.time() - 691200, sender_name = 'Cajero Central', receiver_name = 'Usuario'}
        },
        facturas = {
            {id = 998, label = 'Multa de Tráfico (Alta Velocidad)', amount = 1500, society = 'LSPD', sender = 'Oficial Smith'},
            {id = 999, label = 'Servicios Médicos de Urgencia', amount = 3200, society = 'EMS', sender = 'Dr. House'},
            {id = 1000, label = 'Repuesto de Motor y Chapa', amount = 850, society = 'Mechanic Inc.', sender = 'Bennys Custom'},
            {id = 1001, label = 'Cargo por Estacionamiento Indebido', amount = 250, society = 'LSPD', sender = 'Grúa Central'}
        }
    }
    
    TriggerClientEvent('e-tablet:notificacion', src, 'exito', 'Modo Test: Datos generados temporalmente')
end, false)

RegisterNetEvent('e-tablet:limpiarTest', function()
    local src = source
    DatosTest[src] = nil
end)

if Framework == 'esx' then
    ESX.RegisterServerCallback('e-tablet:obtenerDatosBanco', function(source, cb)
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then cb({}) return end
        local resultado = MySQL.single.await('SELECT iban FROM users WHERE identifier = ?', {xPlayer.identifier})
        cb({
            nombreJugador = xPlayer.getName(),
            ibanJugador = resultado and resultado.iban or 'N/A',
            dineroBanco = xPlayer.getAccount('bank').money,
            dineroEfectivo = xPlayer.getMoney(),
            identificador = xPlayer.identifier
        })
    end)
    
    ESX.RegisterServerCallback('e-tablet:obtenerResumenBanco', function(source, cb)
        local src = source
        if DatosTest[src] then cb({transacciones = DatosTest[src].transacciones}) return end
        
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then cb({transacciones = {}}) return end
        local transacciones = MySQL.query.await('SELECT * FROM e_banking_transactions WHERE receiver_identifier = ? OR sender_identifier = ? ORDER BY date DESC LIMIT 30', {
            xPlayer.identifier,
            xPlayer.identifier
        })
        cb({transacciones = transacciones or {}})
    end)
    
    ESX.RegisterServerCallback('e-tablet:obtenerFacturas', function(source, cb)
        local src = source
        if DatosTest[src] then cb(DatosTest[src].facturas) return end
        
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then cb({}) return end
        local facturas = MySQL.query.await('SELECT id, label, amount, society, sender FROM billing WHERE target = ? AND paid = 0 ORDER BY id DESC', {xPlayer.identifier})
        cb(facturas or {})
    end)
else
    QBCore.Functions.CreateCallback('e-tablet:obtenerDatosBanco', function(source, cb)
        local src = source
        local Jugador = QBCore.Functions.GetPlayer(src)
        if not Jugador then cb({}) return end
        local resultado = MySQL.single.await('SELECT iban FROM players WHERE citizenid = ?', {Jugador.PlayerData.citizenid})
        cb({
            nombreJugador = Jugador.PlayerData.charinfo.firstname .. ' ' .. Jugador.PlayerData.charinfo.lastname,
            ibanJugador = resultado and resultado.iban or 'N/A',
            dineroBanco = Jugador.PlayerData.money.bank or 0,
            dineroEfectivo = Jugador.PlayerData.money.cash or 0,
            identificador = Jugador.PlayerData.citizenid
        })
    end)
    
    QBCore.Functions.CreateCallback('e-tablet:obtenerResumenBanco', function(source, cb)
        local src = source
        if DatosTest[src] then cb({transacciones = DatosTest[src].transacciones}) return end
        
        local Jugador = QBCore.Functions.GetPlayer(src)
        if not Jugador then cb({transacciones = {}}) return end
        local transacciones = MySQL.query.await('SELECT * FROM e_banking_transactions WHERE receiver_identifier = ? OR sender_identifier = ? ORDER BY date DESC LIMIT 30', {
            Jugador.PlayerData.citizenid,
            Jugador.PlayerData.citizenid
        })
        cb({transacciones = transacciones or {}})
    end)
    
    QBCore.Functions.CreateCallback('e-tablet:obtenerFacturas', function(source, cb)
        local src = source
        if DatosTest[src] then cb(DatosTest[src].facturas) return end
        
        local Jugador = QBCore.Functions.GetPlayer(src)
        if not Jugador then cb({}) return end
        local facturas = MySQL.query.await('SELECT * FROM invoices WHERE citizenid = ? AND status = ? ORDER BY id DESC', {Jugador.PlayerData.citizenid, 'unpaid'})
        cb(facturas or {})
    end)
end

RegisterNetEvent('e-tablet:transferirBanco', function(cantidad, idDestinatario)
    local src = source
    local xPlayer = nil
    local idCid = nil
    
    if Framework == 'esx' then
        xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
        idCid = xPlayer.identifier
    else
        xPlayer = QBCore.Functions.GetPlayer(src)
        if not xPlayer then return end
        idCid = xPlayer.PlayerData.citizenid
    end
    
    if DatosTest[src] then
        TriggerClientEvent('e-tablet:notificacion', src, 'error', 'No puedes realizar transferencias reales en modo test')
        return
    end
    
    cantidad = tonumber(cantidad)
    if not cantidad or cantidad <= 0 or not idDestinatario or idDestinatario == '' or idDestinatario == idCid then return end
    
    if Framework == 'esx' then
        if xPlayer.getAccount('bank').money >= cantidad then
            local dest = ESX.GetPlayerFromIdentifier(idDestinatario)
            xPlayer.removeAccountMoney('bank', cantidad)
            if dest then dest.addAccountMoney('bank', cantidad) else MySQL.update('UPDATE users SET bank = bank + ? WHERE identifier = ?', {cantidad, idDestinatario}) end
            MySQL.insert('INSERT INTO e_banking_transactions (receiver_identifier, receiver_name, sender_identifier, sender_name, value, type) VALUES (?, ?, ?, ?, ?, ?)', {idDestinatario, 'Destinatario', idCid, xPlayer.getName(), cantidad, 'transfer'})
            TriggerClientEvent('e-tablet:actualizarSaldoBanco', src, xPlayer.getAccount('bank').money)
        end
    else
        if xPlayer.PlayerData.money.bank >= cantidad then
            local dest = QBCore.Functions.GetPlayerByCitizenId(idDestinatario)
            xPlayer.Functions.RemoveMoney('bank', cantidad)
            if dest then dest.Functions.AddMoney('bank', cantidad) else MySQL.update('UPDATE players SET money = JSON_SET(money, "$.bank", COALESCE(JSON_EXTRACT(money, "$.bank"), 0) + ?) WHERE citizenid = ?', {cantidad, idDestinatario}) end
            MySQL.insert('INSERT INTO e_banking_transactions (receiver_identifier, receiver_name, sender_identifier, sender_name, value, type) VALUES (?, ?, ?, ?, ?, ?)', {idDestinatario, 'Usuario', idCid, xPlayer.PlayerData.charinfo.firstname, cantidad, 'transfer'})
            TriggerClientEvent('e-tablet:actualizarSaldoBanco', src, xPlayer.PlayerData.money.bank)
        end
    end
end)

RegisterNetEvent('e-tablet:pagarFactura', function(idFactura)
    local src = source
    if DatosTest[src] then
        TriggerClientEvent('e-tablet:notificacion', src, 'error', 'No puedes pagar facturas ficticias en modo test')
        return
    end
end)
