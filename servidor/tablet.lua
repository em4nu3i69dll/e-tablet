if not Configuracion.Tablet or not Configuracion.Tablet.Habilitado then return end

local Framework = nil
local ESX = nil
local QBCore = nil

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

if not Framework then
    print('^1[E-TABLET]^7 Error: No se pudo detectar el framework')
    return
end

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

if Framework == 'esx' then
    ESX.RegisterServerCallback('e-tablet:obtenerDatosBanco', function(source, cb)
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        
        if not xPlayer then
            cb({})
            return
        end
        
        local resultado = MySQL.single.await('SELECT iban FROM users WHERE identifier = ?', {xPlayer.identifier})
        
        cb({
            nombreJugador = xPlayer.getName(),
            ibanJugador = resultado and resultado.iban or 'N/A',
            dineroBanco = xPlayer.getAccount('bank').money,
            dineroEfectivo = xPlayer.getMoney(),
            identificador = xPlayer.identifier,
            headshot = nil,
            sexo = tostring(xPlayer.get('sex') or 0)
        })
    end)
    
    ESX.RegisterServerCallback('e-tablet:obtenerResumenBanco', function(source, cb)
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        
        if not xPlayer then
            cb({transacciones = {}, diasGrafica = {0,0,0,0,0,0,0}})
            return
        end
        
        local transacciones = MySQL.query.await('SELECT * FROM e_banking_transactions WHERE receiver_identifier = ? OR sender_identifier = ? ORDER BY date DESC LIMIT 5', {
            xPlayer.identifier,
            xPlayer.identifier
        })
        
        local diasGrafica = {}
        for i = 6, 0, -1 do
            local fecha = os.date('%Y-%m-%d', os.time() - (i * 86400))
            local transaccionesDia = MySQL.query.await('SELECT SUM(value) as total FROM e_banking_transactions WHERE (receiver_identifier = ? OR sender_identifier = ?) AND DATE(date) = ?', {
                xPlayer.identifier,
                xPlayer.identifier,
                fecha
            })
            local total = 0
            if transaccionesDia and transaccionesDia[1] and transaccionesDia[1].total then
                total = tonumber(transaccionesDia[1].total) or 0
            end
            table.insert(diasGrafica, total)
        end
        
        cb({
            transacciones = transacciones or {},
            diasGrafica = diasGrafica
        })
    end)
    
    ESX.RegisterServerCallback('e-tablet:obtenerHistorialBanco', function(source, cb)
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        
        if not xPlayer then
            cb({transacciones = {}, estadisticas = {ingresos = 0, gastos = 0, neto = 0}})
            return
        end
        
        local transacciones = MySQL.query.await('SELECT * FROM e_banking_transactions WHERE receiver_identifier = ? OR sender_identifier = ? ORDER BY date DESC LIMIT 50', {
            xPlayer.identifier,
            xPlayer.identifier
        })
        
        local ingresos = 0
        local gastos = 0
        
        if transacciones then
            for _, t in ipairs(transacciones) do
                local cantidad = tonumber(t.value) or 0
                if t.type == 'deposit' or (t.type == 'transfer' and t.receiver_identifier == xPlayer.identifier) then
                    ingresos = ingresos + cantidad
                elseif t.type == 'withdraw' or (t.type == 'transfer' and t.sender_identifier == xPlayer.identifier) then
                    gastos = gastos + cantidad
                end
            end
        end
        
        cb({
            transacciones = transacciones or {},
            estadisticas = {
                ingresos = ingresos,
                gastos = gastos,
                neto = ingresos - gastos
            }
        })
    end)
    
    ESX.RegisterServerCallback('e-tablet:obtenerPINBanco', function(source, cb)
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        
        if not xPlayer then
            cb({pin = '****'})
            return
        end
        
        local resultado = MySQL.single.await('SELECT pincode FROM users WHERE identifier = ?', {xPlayer.identifier})
        
        cb({
            pin = resultado and resultado.pincode or '****'
        })
    end)
    
    ESX.RegisterServerCallback('e-tablet:obtenerFacturas', function(source, cb)
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        
        if not xPlayer then
            cb({})
            return
        end
        
        local facturas = MySQL.query.await('SELECT id, label, amount, society, sender FROM billing WHERE target = ? AND paid = 0 ORDER BY id DESC', {xPlayer.identifier})
        
        if facturas then
            for i, factura in ipairs(facturas) do
                facturas[i].label = factura.label or factura.society or factura.sender or 'Factura'
            end
        end
        
        cb(facturas or {})
    end)
    
    RegisterNetEvent('e-tablet:depositarBanco', function(cantidad)
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        
        if not xPlayer then return end
        
        cantidad = tonumber(cantidad)
        if not cantidad or cantidad <= 0 then return end
        
        local efectivo = xPlayer.getMoney()
        if cantidad > efectivo then
            TriggerClientEvent('esx:showNotification', src, 'No tienes suficiente efectivo', 'error')
            return
        end
        
        xPlayer.removeMoney(cantidad)
        xPlayer.addAccountMoney('bank', cantidad)
        
        MySQL.insert('INSERT INTO e_banking_transactions (receiver_identifier, receiver_name, sender_identifier, sender_name, value, type) VALUES (?, ?, ?, ?, ?, ?)', {
            xPlayer.identifier,
            xPlayer.getName(),
            xPlayer.identifier,
            xPlayer.getName(),
            cantidad,
            'deposit'
        })
        
        TriggerClientEvent('esx:showNotification', src, 'Depositaste $' .. cantidad, 'success')
        TriggerClientEvent('e-tablet:actualizarSaldoBanco', src, xPlayer.getAccount('bank').money)
    end)
    
    RegisterNetEvent('e-tablet:retirarBanco', function(cantidad)
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        
        if not xPlayer then return end
        
        cantidad = tonumber(cantidad)
        if not cantidad or cantidad <= 0 then return end
        
        local banco = xPlayer.getAccount('bank').money
        if cantidad > banco then
            TriggerClientEvent('esx:showNotification', src, 'No tienes suficiente dinero en el banco', 'error')
            return
        end
        
        xPlayer.removeAccountMoney('bank', cantidad)
        xPlayer.addMoney(cantidad)
        
        MySQL.insert('INSERT INTO e_banking_transactions (receiver_identifier, receiver_name, sender_identifier, sender_name, value, type) VALUES (?, ?, ?, ?, ?, ?)', {
            xPlayer.identifier,
            xPlayer.getName(),
            xPlayer.identifier,
            xPlayer.getName(),
            cantidad,
            'withdraw'
        })
        
        TriggerClientEvent('esx:showNotification', src, 'Retiraste $' .. cantidad, 'success')
        TriggerClientEvent('e-tablet:actualizarSaldoBanco', src, xPlayer.getAccount('bank').money)
    end)
    
    RegisterNetEvent('e-tablet:transferirBanco', function(cantidad, idDestinatario)
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        
        if not xPlayer then return end
        
        cantidad = tonumber(cantidad)
        if not cantidad or cantidad <= 0 then return end
        if not idDestinatario or idDestinatario == '' then return end
        
        if idDestinatario == xPlayer.identifier then
            TriggerClientEvent('esx:showNotification', src, 'No puedes transferirte dinero a ti mismo', 'error')
            return
        end
        
        local banco = xPlayer.getAccount('bank').money
        if cantidad > banco then
            TriggerClientEvent('esx:showNotification', src, 'No tienes suficiente dinero en el banco', 'error')
            return
        end
        
        local resultadoDestinatario = MySQL.single.await('SELECT * FROM users WHERE identifier = ?', {idDestinatario})
        if not resultadoDestinatario then
            TriggerClientEvent('esx:showNotification', src, 'Este ID no existe', 'error')
            return
        end
        
        local destinatario = ESX.GetPlayerFromIdentifier(idDestinatario)
        local nombreDestinatario = resultadoDestinatario.firstname .. ' ' .. resultadoDestinatario.lastname
        
        xPlayer.removeAccountMoney('bank', cantidad)
        
        if destinatario then
            destinatario.addAccountMoney('bank', cantidad)
            TriggerClientEvent('esx:showNotification', destinatario.source, 'Has recibido $' .. cantidad .. ' de ' .. xPlayer.getName(), 'success')
        else
            MySQL.update('UPDATE users SET bank = bank + ? WHERE identifier = ?', {cantidad, idDestinatario})
        end
        
        MySQL.insert('INSERT INTO e_banking_transactions (receiver_identifier, receiver_name, sender_identifier, sender_name, value, type) VALUES (?, ?, ?, ?, ?, ?)', {
            idDestinatario,
            nombreDestinatario,
            xPlayer.identifier,
            xPlayer.getName(),
            cantidad,
            'transfer'
        })
        
        TriggerClientEvent('esx:showNotification', src, 'Transferiste $' .. cantidad .. ' a ' .. nombreDestinatario, 'success')
        TriggerClientEvent('e-tablet:actualizarSaldoBanco', src, xPlayer.getAccount('bank').money)
    end)
    
    RegisterNetEvent('e-tablet:cambiarIBAN', function(nuevoIban)
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        
        if not xPlayer then return end
        
        if not nuevoIban or nuevoIban == '' then return end
        
        nuevoIban = nuevoIban:upper()
        
        local existente = MySQL.single.await('SELECT identifier FROM users WHERE iban = ? AND identifier != ?', {nuevoIban, xPlayer.identifier})
        if existente then
            TriggerClientEvent('esx:showNotification', src, 'Este IBAN ya está en uso', 'error')
            return
        end
        
        MySQL.update('UPDATE users SET iban = ? WHERE identifier = ?', {nuevoIban, xPlayer.identifier})
        TriggerClientEvent('esx:showNotification', src, 'IBAN actualizado a ' .. nuevoIban, 'success')
    end)
    
    RegisterNetEvent('e-tablet:cambiarPIN', function(nuevoPin)
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        
        if not xPlayer then return end
        
        if not nuevoPin or nuevoPin == '' or #nuevoPin ~= 4 or not tonumber(nuevoPin) then
            TriggerClientEvent('esx:showNotification', src, 'El PIN debe tener 4 dígitos numéricos', 'error')
            return
        end
        
        MySQL.update('UPDATE users SET pincode = ? WHERE identifier = ?', {nuevoPin, xPlayer.identifier})
        TriggerClientEvent('esx:showNotification', src, 'PIN actualizado', 'success')
    end)
    
    RegisterNetEvent('e-tablet:pagarFactura', function(idFactura)
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        
        if not xPlayer then return end
        
        local factura = MySQL.single.await('SELECT * FROM billing WHERE id = ? AND target = ? AND paid = 0', {idFactura, xPlayer.identifier})
        
        if not factura then
            TriggerClientEvent('esx:showNotification', src, 'Factura no encontrada', 'error')
            return
        end
        
        local cantidad = tonumber(factura.amount)
        local banco = xPlayer.getAccount('bank').money
        
        if cantidad > banco then
            TriggerClientEvent('esx:showNotification', src, 'No tienes suficiente dinero en el banco', 'error')
            return
        end
        
        xPlayer.removeAccountMoney('bank', cantidad)
        MySQL.update('UPDATE billing SET paid = 1 WHERE id = ?', {idFactura})
        
        TriggerClientEvent('esx:showNotification', src, 'Factura pagada: $' .. cantidad, 'success')
        TriggerClientEvent('e-tablet:actualizarSaldoBanco', src, xPlayer.getAccount('bank').money)
    end)
else
    QBCore.Functions.CreateCallback('e-tablet:obtenerDatosBanco', function(source, cb)
        local src = source
        local Jugador = QBCore.Functions.GetPlayer(src)
        
        if not Jugador then
            cb({})
            return
        end
        
        local resultado = MySQL.single.await('SELECT iban FROM players WHERE citizenid = ?', {Jugador.PlayerData.citizenid})
        
        cb({
            nombreJugador = Jugador.PlayerData.charinfo.firstname .. ' ' .. Jugador.PlayerData.charinfo.lastname,
            ibanJugador = resultado and resultado.iban or 'N/A',
            dineroBanco = Jugador.PlayerData.money.bank or 0,
            dineroEfectivo = Jugador.PlayerData.money.cash or 0,
            identificador = Jugador.PlayerData.citizenid,
            headshot = nil,
            sexo = tostring(Jugador.PlayerData.charinfo.gender or 0)
        })
    end)
    
    QBCore.Functions.CreateCallback('e-tablet:obtenerResumenBanco', function(source, cb)
        local src = source
        local Jugador = QBCore.Functions.GetPlayer(src)
        
        if not Jugador then
            cb({transacciones = {}, diasGrafica = {0,0,0,0,0,0,0}})
            return
        end
        
        local transacciones = MySQL.query.await('SELECT * FROM e_banking_transactions WHERE receiver_identifier = ? OR sender_identifier = ? ORDER BY date DESC LIMIT 5', {
            Jugador.PlayerData.citizenid,
            Jugador.PlayerData.citizenid
        })
        
        local diasGrafica = {}
        for i = 6, 0, -1 do
            local fecha = os.date('%Y-%m-%d', os.time() - (i * 86400))
            local transaccionesDia = MySQL.query.await('SELECT SUM(value) as total FROM e_banking_transactions WHERE (receiver_identifier = ? OR sender_identifier = ?) AND DATE(date) = ?', {
                Jugador.PlayerData.citizenid,
                Jugador.PlayerData.citizenid,
                fecha
            })
            local total = 0
            if transaccionesDia and transaccionesDia[1] and transaccionesDia[1].total then
                total = tonumber(transaccionesDia[1].total) or 0
            end
            table.insert(diasGrafica, total)
        end
        
        cb({
            transacciones = transacciones or {},
            diasGrafica = diasGrafica
        })
    end)
    
    QBCore.Functions.CreateCallback('e-tablet:obtenerHistorialBanco', function(source, cb)
        local src = source
        local Jugador = QBCore.Functions.GetPlayer(src)
        
        if not Jugador then
            cb({transacciones = {}, estadisticas = {ingresos = 0, gastos = 0, neto = 0}})
            return
        end
        
        local transacciones = MySQL.query.await('SELECT * FROM e_banking_transactions WHERE receiver_identifier = ? OR sender_identifier = ? ORDER BY date DESC LIMIT 50', {
            Jugador.PlayerData.citizenid,
            Jugador.PlayerData.citizenid
        })
        
        local ingresos = 0
        local gastos = 0
        
        if transacciones then
            for _, t in ipairs(transacciones) do
                local cantidad = tonumber(t.value) or 0
                if t.type == 'deposit' or (t.type == 'transfer' and t.receiver_identifier == Jugador.PlayerData.citizenid) then
                    ingresos = ingresos + cantidad
                elseif t.type == 'withdraw' or (t.type == 'transfer' and t.sender_identifier == Jugador.PlayerData.citizenid) then
                    gastos = gastos + cantidad
                end
            end
        end
        
        cb({
            transacciones = transacciones or {},
            estadisticas = {
                ingresos = ingresos,
                gastos = gastos,
                neto = ingresos - gastos
            }
        })
    end)
    
    QBCore.Functions.CreateCallback('e-tablet:obtenerPINBanco', function(source, cb)
        local src = source
        local Jugador = QBCore.Functions.GetPlayer(src)
        
        if not Jugador then
            cb({pin = '****'})
            return
        end
        
        local resultado = MySQL.single.await('SELECT pincode FROM players WHERE citizenid = ?', {Jugador.PlayerData.citizenid})
        
        cb({
            pin = resultado and resultado.pincode or '****'
        })
    end)
    
    QBCore.Functions.CreateCallback('e-tablet:obtenerFacturas', function(source, cb)
        local src = source
        local Jugador = QBCore.Functions.GetPlayer(src)
        
        if not Jugador then
            cb({})
            return
        end
        
        local facturas = MySQL.query.await('SELECT * FROM invoices WHERE citizenid = ? AND status = ? ORDER BY id DESC', {Jugador.PlayerData.citizenid, 'unpaid'})
        
        cb(facturas or {})
    end)
    
    RegisterNetEvent('e-tablet:depositarBanco', function(cantidad)
        local src = source
        local Jugador = QBCore.Functions.GetPlayer(src)
        
        if not Jugador then return end
        
        cantidad = tonumber(cantidad)
        if not cantidad or cantidad <= 0 then return end
        
        local efectivo = Jugador.PlayerData.money.cash or 0
        if cantidad > efectivo then
            TriggerClientEvent('QBCore:Notify', src, 'No tienes suficiente efectivo', 'error')
            return
        end
        
        Jugador.Functions.RemoveMoney('cash', cantidad)
        Jugador.Functions.AddMoney('bank', cantidad)
        
        MySQL.insert('INSERT INTO e_banking_transactions (receiver_identifier, receiver_name, sender_identifier, sender_name, value, type) VALUES (?, ?, ?, ?, ?, ?)', {
            Jugador.PlayerData.citizenid,
            Jugador.PlayerData.charinfo.firstname .. ' ' .. Jugador.PlayerData.charinfo.lastname,
            Jugador.PlayerData.citizenid,
            Jugador.PlayerData.charinfo.firstname .. ' ' .. Jugador.PlayerData.charinfo.lastname,
            cantidad,
            'deposit'
        })
        
        TriggerClientEvent('QBCore:Notify', src, 'Depositaste $' .. cantidad, 'success')
        TriggerClientEvent('e-tablet:actualizarSaldoBanco', src, Jugador.PlayerData.money.bank or 0)
    end)
    
    RegisterNetEvent('e-tablet:retirarBanco', function(cantidad)
        local src = source
        local Jugador = QBCore.Functions.GetPlayer(src)
        
        if not Jugador then return end
        
        cantidad = tonumber(cantidad)
        if not cantidad or cantidad <= 0 then return end
        
        local banco = Jugador.PlayerData.money.bank or 0
        if cantidad > banco then
            TriggerClientEvent('QBCore:Notify', src, 'No tienes suficiente dinero en el banco', 'error')
            return
        end
        
        Jugador.Functions.RemoveMoney('bank', cantidad)
        Jugador.Functions.AddMoney('cash', cantidad)
        
        MySQL.insert('INSERT INTO e_banking_transactions (receiver_identifier, receiver_name, sender_identifier, sender_name, value, type) VALUES (?, ?, ?, ?, ?, ?)', {
            Jugador.PlayerData.citizenid,
            Jugador.PlayerData.charinfo.firstname .. ' ' .. Jugador.PlayerData.charinfo.lastname,
            Jugador.PlayerData.citizenid,
            Jugador.PlayerData.charinfo.firstname .. ' ' .. Jugador.PlayerData.charinfo.lastname,
            cantidad,
            'withdraw'
        })
        
        TriggerClientEvent('QBCore:Notify', src, 'Retiraste $' .. cantidad, 'success')
        TriggerClientEvent('e-tablet:actualizarSaldoBanco', src, Jugador.PlayerData.money.bank or 0)
    end)
    
    RegisterNetEvent('e-tablet:transferirBanco', function(cantidad, idDestinatario)
        local src = source
        local Jugador = QBCore.Functions.GetPlayer(src)
        
        if not Jugador then return end
        
        cantidad = tonumber(cantidad)
        if not cantidad or cantidad <= 0 then return end
        if not idDestinatario or idDestinatario == '' then return end
        
        if idDestinatario == Jugador.PlayerData.citizenid then
            TriggerClientEvent('QBCore:Notify', src, 'No puedes transferirte dinero a ti mismo', 'error')
            return
        end
        
        local banco = Jugador.PlayerData.money.bank or 0
        if cantidad > banco then
            TriggerClientEvent('QBCore:Notify', src, 'No tienes suficiente dinero en el banco', 'error')
            return
        end
        
        local resultadoDestinatario = MySQL.single.await('SELECT * FROM players WHERE citizenid = ?', {idDestinatario})
        if not resultadoDestinatario then
            TriggerClientEvent('QBCore:Notify', src, 'Este ID no existe', 'error')
            return
        end
        
        local destinatario = QBCore.Functions.GetPlayerByCitizenId(idDestinatario)
        local nombreDestinatario = resultadoDestinatario.charinfo and json.decode(resultadoDestinatario.charinfo) or {}
        local nombreCompletoDestinatario = (nombreDestinatario.firstname or '') .. ' ' .. (nombreDestinatario.lastname or 'Usuario')
        
        Jugador.Functions.RemoveMoney('bank', cantidad)
        
        if destinatario then
            destinatario.Functions.AddMoney('bank', cantidad)
            TriggerClientEvent('QBCore:Notify', destinatario.PlayerData.source, 'Has recibido $' .. cantidad .. ' de ' .. Jugador.PlayerData.charinfo.firstname .. ' ' .. Jugador.PlayerData.charinfo.lastname, 'success')
        else
            MySQL.update('UPDATE players SET money = JSON_SET(COALESCE(money, "{}"), "$.bank", COALESCE(JSON_EXTRACT(money, "$.bank"), 0) + ?) WHERE citizenid = ?', {cantidad, idDestinatario})
        end
        
        local nombreRemitente = Jugador.PlayerData.charinfo.firstname .. ' ' .. Jugador.PlayerData.charinfo.lastname
        MySQL.insert('INSERT INTO e_banking_transactions (receiver_identifier, receiver_name, sender_identifier, sender_name, value, type) VALUES (?, ?, ?, ?, ?, ?)', {
            idDestinatario,
            nombreCompletoDestinatario,
            Jugador.PlayerData.citizenid,
            nombreRemitente,
            cantidad,
            'transfer'
        })
        
        TriggerClientEvent('QBCore:Notify', src, 'Transferiste $' .. cantidad .. ' a ' .. nombreCompletoDestinatario, 'success')
        TriggerClientEvent('e-tablet:actualizarSaldoBanco', src, Jugador.PlayerData.money.bank or 0)
    end)
    
    RegisterNetEvent('e-tablet:cambiarIBAN', function(nuevoIban)
        local src = source
        local Jugador = QBCore.Functions.GetPlayer(src)
        
        if not Jugador then return end
        
        if not nuevoIban or nuevoIban == '' then return end
        
        nuevoIban = nuevoIban:upper()
        
        local existente = MySQL.single.await('SELECT citizenid FROM players WHERE iban = ? AND citizenid != ?', {nuevoIban, Jugador.PlayerData.citizenid})
        if existente then
            TriggerClientEvent('QBCore:Notify', src, 'Este IBAN ya está en uso', 'error')
            return
        end
        
        MySQL.update('UPDATE players SET iban = ? WHERE citizenid = ?', {nuevoIban, Jugador.PlayerData.citizenid})
        TriggerClientEvent('QBCore:Notify', src, 'IBAN actualizado a ' .. nuevoIban, 'success')
    end)
    
    RegisterNetEvent('e-tablet:cambiarPIN', function(nuevoPin)
        local src = source
        local Jugador = QBCore.Functions.GetPlayer(src)
        
        if not Jugador then return end
        
        if not nuevoPin or nuevoPin == '' or #nuevoPin ~= 4 or not tonumber(nuevoPin) then
            TriggerClientEvent('QBCore:Notify', src, 'El PIN debe tener 4 dígitos numéricos', 'error')
            return
        end
        
        MySQL.update('UPDATE players SET pincode = ? WHERE citizenid = ?', {nuevoPin, Jugador.PlayerData.citizenid})
        TriggerClientEvent('QBCore:Notify', src, 'PIN actualizado', 'success')
    end)
    
    RegisterNetEvent('e-tablet:pagarFactura', function(idFactura)
        local src = source
        local Jugador = QBCore.Functions.GetPlayer(src)
        
        if not Jugador then return end
        
        local factura = MySQL.single.await('SELECT * FROM invoices WHERE id = ? AND citizenid = ? AND status = ?', {idFactura, Jugador.PlayerData.citizenid, 'unpaid'})
        
        if not factura then
            TriggerClientEvent('QBCore:Notify', src, 'Factura no encontrada', 'error')
            return
        end
        
        local cantidad = tonumber(factura.amount)
        local banco = Jugador.PlayerData.money.bank or 0
        
        if cantidad > banco then
            TriggerClientEvent('QBCore:Notify', src, 'No tienes suficiente dinero en el banco', 'error')
            return
        end
        
        Jugador.Functions.RemoveMoney('bank', cantidad)
        MySQL.update('UPDATE invoices SET status = ? WHERE id = ?', {'paid', idFactura})
        
        TriggerClientEvent('QBCore:Notify', src, 'Factura pagada: $' .. cantidad, 'success')
        TriggerClientEvent('e-tablet:actualizarSaldoBanco', src, Jugador.PlayerData.money.bank or 0)
    end)
end
