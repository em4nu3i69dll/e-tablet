function reproducirSonido(tipo) {
    const sonido = document.getElementById(`sonido-${tipo}`);
    if (sonido) {
        sonido.currentTime = 0;
        sonido.play().catch(e => { });
    }
}

$(document).ready(function () {
    $('.pagina-info').show();
    $('.pantalla-bloqueo').show();

    let bloqueado = true;
    let inicioY = 0;
    let arrastrando = false;

    $('#area-deslizar').on('mousedown touchstart', function (e) {
        arrastrando = true;
        inicioY = e.pageY || e.originalEvent.touches[0].pageY;
    });

    $(document).on('mousemove touchmove', function (e) {
        if (!arrastrando || !bloqueado) return;

        let actualY = e.pageY || e.originalEvent.touches[0].pageY;
        let diferencia = inicioY - actualY;

        if (diferencia > 0) {
            $('.pantalla-bloqueo').css('transform', `translateY(-${diferencia}px)`);
            let opacidad = 1 - (diferencia / 300);
            if (opacidad < 0) opacidad = 0;
            $('.pantalla-bloqueo').css('opacity', opacidad);
        }
    });

    $(document).on('mouseup touchend', function (e) {
        if (!arrastrando) return;
        arrastrando = false;

        const finalY = e.pageY || (e.originalEvent.changedTouches ? e.originalEvent.changedTouches[0].pageY : inicioY);
        if (inicioY - finalY > 100) {
            desbloquearTablet();
        } else {
            $('.pantalla-bloqueo').css({ 'transform': 'translateY(0)', 'opacity': '1' });
        }
    });

    function desbloquearTablet() {
        bloqueado = false;
        reproducirSonido('apertura');
        $('.pantalla-bloqueo').css({ 'transform': 'translateY(-100%)', 'opacity': '0' });
        $('.pantalla-tablet').removeClass('bloqueado');
        setTimeout(() => {
            $('.pantalla-bloqueo').hide();
        }, 600);
    }

    $('.item-dock').on('click', function () {
        const id = $(this).attr('id');
        if ($(this).hasClass('activo')) return;

        reproducirSonido('cambio');

        $('.item-dock').removeClass('activo');
        $(this).addClass('activo');

        $('.seccion-app').fadeOut(150);

        setTimeout(() => {
            let appId = id === 'dock-banco' ? 'banco' : id;
            $(`#app-${appId}`).fadeIn(250);

            if (id === 'dock-banco') {
                setTimeout(cargarBancoSimple, 50);
            } else if (id === 'facturas') {
                setTimeout(cargarFacturas, 50);
            }
        }, 150);
    });

    $(document).on('click', '#boton-transferir-banco', function () {
        reproducirSonido('click');
        $('#modal-transferir-banco').fadeIn(300);
    });

    $(document).on('click', '.cerrar-modal-banco', function () {
        reproducirSonido('click');
        const modal = $(this).data('modal');
        $(`#modal-${modal}-banco`).fadeOut(300);
    });

    $(document).on('click', '#confirmar-transferir-banco', function () {
        const cantidad = parseInt($('#entrada-transferir-cantidad').val());
        const idDestinatario = $('#entrada-transferir-id').val().trim();

        if (cantidad && cantidad > 0 && idDestinatario) {
            $.post('https://e-tablet/accionBanco', JSON.stringify({
                accion: 'transferir',
                cantidad: cantidad,
                idDestinatario: idDestinatario
            }), function (respuesta) {
                if (respuesta && respuesta.exito !== false) {
                    cargarBancoSimple();
                }
            });
            $('#modal-transferir-banco').fadeOut(300);
            $('#entrada-transferir-cantidad').val('');
            $('#entrada-transferir-id').val('');
            $('#confirmar-transferir-banco').prop('disabled', true);
        }
    });

    $(document).on('input', '#entrada-transferir-cantidad, #entrada-transferir-id', function () {
        const cantidad = $('#entrada-transferir-cantidad').val();
        const idDestinatario = $('#entrada-transferir-id').val().trim();
        $('#confirmar-transferir-banco').prop('disabled', !(cantidad && cantidad > 0 && idDestinatario));
    });

    $(document).on('input', '#entrada-busqueda-banco', function () {
        filtrarTransaccionesBanco($(this).val().trim().toLowerCase());
    });

    $(document).keyup(function (e) {
        if (e.keyCode == 27) {
            reproducirSonido('cierre');
            $('.contenedor-tablet').fadeOut(200, function () {
                $('body').hide();
                $('.notificacion').remove();
            });
            if (window.parent && window.parent !== window) {
                window.parent.postMessage({ accion: 'cerrarTablet' }, '*');
            }
            $.post('https://e-tablet/escape', JSON.stringify({}));
        }
    });

    function actualizarHora() {
        const ahora = new Date();
        const horas = String(ahora.getHours()).padStart(2, '0');
        const minutos = String(ahora.getMinutes()).padStart(2, '0');
        const cadenaHora = `${horas}:${minutos}`;

        $('#hora-estado').text(cadenaHora);
        $('#hora-bloqueo').text(cadenaHora);

        const dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
        const meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
        const cadenaFecha = `${dias[ahora.getDay()]}, ${ahora.getDate()} de ${meses[ahora.getMonth()]}`;
        $('#fecha-bloqueo').text(cadenaFecha);
    }

    setInterval(actualizarHora, 1000);
    actualizarHora();
});

window.addEventListener('message', function (event) {
    const d = event.data;
    if (d.accion === 'abrir' && d.mostrar == true) {
        $('body').show();
        $('.contenedor-tablet').css('display', 'flex').hide().fadeIn(300);
        $('.pagina-info').show();
        $('.pantalla-bloqueo').show().css({ 'transform': 'translateY(0)', 'opacity': '1' });
        $('.pantalla-tablet').addClass('bloqueado');

        $('.item-dock').removeClass('activo');
        $('#inicio').addClass('activo');
        $('.seccion-app').hide();
        $('#app-inicio').show();

        if (d.nombre) $('.nombre').html(d.nombre);
        if (d.trabajo) $('#trabajo').html(d.trabajo);
        if (d.grado) $('#grado').html(' • ' + d.grado);
        if (d.efectivo !== undefined) $('#efectivo').html('$' + d.efectivo.toLocaleString());
        if (d.banco !== undefined) $('#banco').html('$' + d.banco.toLocaleString());
        if (d.telefono) $('#telefono').html(d.telefono);
        if (d.ciudadano) $('#ciudadano').html(d.ciudadano);
        if (d.id !== undefined) $('#id-jugador').html(d.id);
        if (d.totalJugadores !== undefined) $('#total-jugadores').html(d.totalJugadores);

        if (d.headshot) {
            $('#foto-jugador').attr('src', `https://nui-img/${d.headshot}/${d.headshot}`);
        } else {
            $('#foto-jugador').attr('src', './img/default.png');
        }

        if (d.policia !== undefined) $('#conteo-policia').html(d.policia);
        if (d.ems !== undefined) $('#conteo-ems').html(d.ems);
        if (d.mecanico !== undefined) $('#conteo-mecanico').html(d.mecanico);
        if (d.taxi !== undefined) $('#conteo-taxi').html(d.taxi);

    } else if (d.accion == 'cerrar' || d.mostrar == false) {
        reproducirSonido('cierre');
        $('.contenedor-tablet').fadeOut(200, function () {
            $('body').hide();
            $('.notificacion').remove();
        });
        $('#foto-jugador').attr('src', '');
    } else if (d.accion == 'notificacion') {
        mostrarNotificacion(d.tipo, d.mensaje);
    } else if (d.accion == 'actualizarSaldoBanco') {
        if (d.saldo !== undefined) $('#banco').html('$' + d.saldo.toLocaleString());
    }
});

let datosUsuarioBanco = { dineroBanco: 0, identificador: '' };
let todasTransaccionesBanco = [];

function cargarBancoSimple() {
    $('#lista-transacciones-banco').html('<div class="estado-lista-vacia"><i class="fas fa-spinner fa-spin"></i><p>Sincronizando movimientos bancarios...</p></div>');

    $.post('https://e-tablet/obtenerDatosBanco', JSON.stringify({}), function (datos) {
        if (datos) {
            datosUsuarioBanco.dineroBanco = datos.dineroBanco || 0;
            datosUsuarioBanco.identificador = datos.identificador || '';
            $('#saldo-banco').text('$' + datosUsuarioBanco.dineroBanco.toLocaleString());
        }
    });

    $.post('https://e-tablet/obtenerResumenBanco', JSON.stringify({}), function (datos) {
        todasTransaccionesBanco = datos.transacciones || [];
        $('#entrada-busqueda-banco').val('');
        renderizarTransaccionesBanco(todasTransaccionesBanco);
    }).fail(function () {
        $('#lista-transacciones-banco').html('<div class="estado-lista-vacia"><i class="fas fa-exclamation-triangle"></i><p>Error de conexión bancaria</p></div>');
    });
}

function renderizarTransaccionesBanco(transacciones) {
    const list = $('#lista-transacciones-banco');
    if (transacciones.length === 0) {
        list.html('<div class="estado-lista-vacia"><i class="fas fa-history"></i><p>No hay movimientos registrados en esta cuenta todavía.</p></div>');
        return;
    }

    let html = '';
    const items = transacciones.slice(0, 30);

    items.forEach(t => {
        const tipo = t.type || 'transfer';
        const cantidad = parseFloat(t.value || 0);
        const esPositivo = tipo === 'deposit' || (tipo === 'transfer' && t.receiver_identifier === (datosUsuarioBanco.identificador || ''));
        const icono = esPositivo ? 'fa-plus-circle' : 'fa-minus-circle';
        const clase = esPositivo ? 'cantidad-positiva-banco' : 'cantidad-negativa-banco';
        const monto = esPositivo ? `+$${cantidad.toLocaleString()}` : `-$${Math.abs(cantidad).toLocaleString()}`;

        let label = 'Operación';
        if (tipo === 'deposit') label = 'Depósito';
        else if (tipo === 'withdraw') label = 'Retiro de Efectivo';
        else if (tipo === 'transfer') {
            label = t.receiver_identifier === datosUsuarioBanco.identificador ? `De: ${t.sender_name || 'Desconocido'}` : `A: ${t.receiver_name || 'Desconocido'}`;
        }

        html += `
            <div class="item-transaccion-banco">
                <div class="icono-transaccion-banco ${clase}">
                    <i class="fas ${icono}"></i>
                </div>
                <div class="info-transaccion-banco">
                    <span class="tipo-transaccion-banco">${label}</span>
                    <span class="fecha-transaccion-banco">${formatearFechaBanco(t.date)}</span>
                </div>
                <div class="cantidad-transaccion-banco ${clase}">${monto}</div>
            </div>
        `;
    });
    list.html(html);
}

function filtrarTransaccionesBanco(q) {
    if (!q) return renderizarTransaccionesBanco(todasTransaccionesBanco);
    const filtered = todasTransaccionesBanco.filter(t => {
        const val = Math.abs(parseFloat(t.value || 0)).toString();
        const typeStr = (t.type === 'deposit' ? 'depósito' : t.type === 'withdraw' ? 'retiro' : 'transferencia');
        return val.includes(q) || typeStr.includes(q) || (t.sender_name || '').toLowerCase().includes(q) || (t.receiver_name || '').toLowerCase().includes(q);
    });
    renderizarTransaccionesBanco(filtered);
}

function formatearFechaBanco(ts) {
    if (!ts) return 'N/A';
    try {
        let d = new Date(isNaN(ts) ? ts : (String(ts).length > 10 ? parseInt(ts) : parseInt(ts) * 1000));
        if (!isNaN(d.getTime())) {
            const m = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
            return `${d.getDate()} ${m[d.getMonth()]} ${d.getFullYear()}`;
        }
    } catch (e) { }
    return 'N/A';
}

function renderizarFacturas(facturas) {
    const list = $('#lista-facturas');
    if (!facturas || facturas.length === 0) {
        list.html('<div class="estado-lista-vacia"><i class="fas fa-check-double"></i><p>¡Todo en orden! No tienes facturas pendientes de pago en este momento.</p></div>');
        return;
    }

    let html = '';
    facturas.forEach(f => {
        const amt = parseFloat(f.amount || 0);
        const l = f.label || 'Concepto no especificado';
        const soc = f.society || 'Empresa Privada';
        const snd = f.sender || 'Administración';
        const id = f.id || f.billid || 0;

        html += `
            <div class="tarjeta-factura">
                <div class="seccion-info-factura">
                    <div class="cabecera-factura">
                        <span class="sociedad-factura">${soc}</span>
                        <span class="emisor-factura">Emitido por: ${snd}</span>
                    </div>
                    <span class="etiqueta-factura">${l}</span>
                </div>
                <div class="seccion-pago-factura">
                    <span class="cantidad-factura">$${amt.toLocaleString()}</span>
                    <button class="boton-pagar-factura" onclick="pagarFactura(${id})">Pagar Ahora</button>
                </div>
            </div>
        `;
    });
    list.html(html);
}

function cargarFacturas() {
    $('#lista-facturas').html('<div class="estado-lista-vacia"><i class="fas fa-spinner fa-spin"></i><p>Sincronizando recibos pendientes...</p></div>');
    $.post('https://e-tablet/obtenerFacturas', JSON.stringify({}), renderizarFacturas).fail(() => {
        $('#lista-facturas').html('<div class="estado-lista-vacia"><i class="fas fa-exclamation-triangle"></i><p>Error de conexión con el servidor de facturación</p></div>');
    });
}

function pagarFactura(id) {
    reproducirSonido('click');
    $.post('https://e-tablet/pagarFactura', JSON.stringify({ id: id }), function (r) {
        if (r && r.exito !== false) {
            mostrarNotificacion('exito', 'Transacción completada: Factura pagada');
            cargarFacturas();
        } else {
            mostrarNotificacion('error', 'Fondos insuficientes o error en la transacción');
        }
    }).fail(() => mostrarNotificacion('error', 'Error de comunicación bancaria'));
}

window.pagarFactura = pagarFactura;

function mostrarNotificacion(t, m) {
    const n = $(`<div class="notificacion notificacion-${t}"><i class="fas fa-${t === 'exito' ? 'check-circle' : 'exclamation-circle'}"></i><span>${m}</span></div>`);
    $('body').append(n);
    setTimeout(() => n.addClass('mostrar'), 100);
    setTimeout(() => {
        n.removeClass('mostrar');
        setTimeout(() => n.remove(), 500);
    }, 4000);
}
