if not Configuracion.Tablet or not Configuracion.Tablet.Habilitado then 
    return 
end

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
    return
end

local tabletAbierta = false
local propTablet = nil
local headshotActual = nil

RegisterKeyMapping('e-tablet', 'Abrir Tablet', 'keyboard', Configuracion.Tablet.TeclaAbrir)
TriggerEvent('chat:removeSuggestion', '/e-tablet')

RegisterCommand('tablet', function()
    if tabletAbierta then
        CerrarTablet()
    else
        AbrirTablet()
    end
end)

RegisterCommand('e-tablet', function()
    if tabletAbierta then
        CerrarTablet()
    else
        AbrirTablet()
    end
end)

function AbrirTablet()
    if tabletAbierta then return end
    tabletAbierta = true
    ReproducirAnimacion()
    TriggerServerEvent('e-tablet:obtenerDatosJugador')
end

local function CrearHeadshotPed()
    if headshotActual then
        UnregisterPedheadshot(headshotActual)
        headshotActual = nil
    end
    
    local ped = PlayerPedId()
    local headshot = RegisterPedheadshot(ped)
    
    local tiempoEspera = 1000
    local tiempo = 0
    while not IsPedheadshotReady(headshot) and tiempo < tiempoEspera do
        Wait(50)
        tiempo = tiempo + 50
    end
    
    if IsPedheadshotReady(headshot) then
        headshotActual = headshot
        return GetPedheadshotTxdString(headshot)
    else
        UnregisterPedheadshot(headshot)
        return nil
    end
end

RegisterNetEvent('e-tablet:recibirDatosJugador', function(datos)
    local headshotTxd = CrearHeadshotPed()
    
    SendNUIMessage({
        accion = 'abrir',
        mostrar = true,
        ciudadano = datos.ciudadano,
        nombre = datos.nombre,
        fechaNacimiento = datos.fechaNacimiento,
        efectivo = datos.efectivo,
        banco = datos.banco,
        trabajo = datos.trabajo,
        grado = datos.grado,
        telefono = datos.telefono,
        id = datos.id,
        headshot = headshotTxd,
        policia = datos.policia,
        ems = datos.ems,
        mecanico = datos.mecanico,
        taxi = datos.taxi,
        totalJugadores = datos.totalJugadores
    })
    SetNuiFocus(true, true)
end)

RegisterNetEvent('e-tablet:notificacion', function(tipo, mensaje)
    SendNUIMessage({
        accion = 'notificacion',
        tipo = tipo,
        mensaje = mensaje
    })
    
    if tipo == 'exito' then
        if Framework == 'esx' then
            ESX.ShowNotification(mensaje, 'success', 5000)
        else
            QBCore.Functions.Notify(mensaje, 'success', 5000)
        end
    elseif tipo == 'error' then
        if Framework == 'esx' then
            ESX.ShowNotification(mensaje, 'error', 5000)
        else
            QBCore.Functions.Notify(mensaje, 'error', 5000)
        end
    end
end)

RegisterNUICallback('obtenerDatosBanco', function(datos, cb)
    if Framework == 'esx' then
        ESX.TriggerServerCallback('e-tablet:obtenerDatosBanco', function(datosBanco)
            local headshotTxd = CrearHeadshotPed()
            if headshotTxd then datosBanco.headshot = headshotTxd end
            cb(datosBanco)
        end)
    else
        QBCore.Functions.TriggerCallback('e-tablet:obtenerDatosBanco', function(datosBanco)
            local headshotTxd = CrearHeadshotPed()
            if headshotTxd then datosBanco.headshot = headshotTxd end
            cb(datosBanco)
        end)
    end
end)

RegisterNUICallback('obtenerResumenBanco', function(datos, cb)
    if Framework == 'esx' then
        ESX.TriggerServerCallback('e-tablet:obtenerResumenBanco', function(datosResumen)
            cb(datosResumen)
        end)
    else
        QBCore.Functions.TriggerCallback('e-tablet:obtenerResumenBanco', function(datosResumen)
            cb(datosResumen)
        end)
    end
end)

RegisterNUICallback('obtenerFacturas', function(datos, cb)
    if Framework == 'esx' then
        ESX.TriggerServerCallback('e-tablet:obtenerFacturas', function(facturas)
            cb(facturas or {})
        end)
    else
        QBCore.Functions.TriggerCallback('e-tablet:obtenerFacturas', function(facturas)
            cb(facturas or {})
        end)
    end
end)

RegisterNUICallback('pagarFactura', function(datos, cb)
    if datos.id then
        TriggerServerEvent('e-tablet:pagarFactura', datos.id)
    end
    cb('ok')
end)

RegisterNUICallback('accionBanco', function(datos, cb)
    TriggerServerEvent('e-tablet:transferirBanco', datos.cantidad, datos.idDestinatario)
    cb('ok')
end)

function CerrarTablet()
    if not tabletAbierta then return end
    tabletAbierta = false
    SetNuiFocus(false, false)
    TriggerServerEvent('e-tablet:limpiarTest')
    SendNUIMessage({ accion = 'cerrar', mostrar = false })
    if headshotActual then UnregisterPedheadshot(headshotActual) headshotActual = nil end
    DetenerAnimacion()
end

function ReproducirAnimacion()
    local jugadorPed = PlayerPedId()
    local diccionarioAnim = Configuracion.Tablet.Animacion.diccionario
    local nombreAnim = Configuracion.Tablet.Animacion.animacion
    local modeloProp = Configuracion.Tablet.Animacion.prop
    local hueso = Configuracion.Tablet.Animacion.hueso
    local pos = Configuracion.Tablet.Animacion.posicion
    local rot = Configuracion.Tablet.Animacion.rotacion
    RequestAnimDict(diccionarioAnim)
    while not HasAnimDictLoaded(diccionarioAnim) do Wait(100) end
    RequestModel(modeloProp)
    while not HasModelLoaded(modeloProp) do Wait(100) end
    propTablet = CreateObject(GetHashKey(modeloProp), 0.0, 0.0, 0.0, true, true, true)
    AttachEntityToEntity(propTablet, jugadorPed, GetPedBoneIndex(jugadorPed, hueso), pos[1], pos[2], pos[3], rot[1], rot[2], rot[3], true, true, false, true, 1, true)
    TaskPlayAnim(jugadorPed, diccionarioAnim, nombreAnim, 3.0, 3.0, -1, 49, 0, false, false, false)
end

function DetenerAnimacion()
    local jugadorPed = PlayerPedId()
    local diccionarioAnim = Configuracion.Tablet.Animacion.diccionario
    if propTablet then DeleteObject(propTablet) propTablet = nil end
    StopAnimTask(jugadorPed, diccionarioAnim, Configuracion.Tablet.Animacion.animacion, 1.0)
    ClearPedTasks(jugadorPed)
end

RegisterNUICallback('escape', function(datos, cb) CerrarTablet() cb('ok') end)
RegisterNUICallback('cerrar', function(datos, cb) CerrarTablet() cb('ok') end)
