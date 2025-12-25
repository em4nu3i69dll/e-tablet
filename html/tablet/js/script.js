function reproducirSonido(tipo) {
    const sonido = document.getElementById(`sonido-${tipo}`);
    if (sonido) {
        sonido.currentTime = 0;
        sonido.play().catch(e => console.log('Error reproduciendo sonido:', e));
    }
}

$(document).ready(function() {
    
    $('.pagina-info').show();
    $('.pantalla-bloqueo').show();
    
    let bloqueado = true;
    
    let inicioY = 0;
    let arrastrando = false;
    
    $('#area-deslizar').on('mousedown touchstart', function(e) {
        arrastrando = true;
        inicioY = e.pageY || e.originalEvent.touches[0].pageY;
    });
    
    $(document).on('mousemove touchmove', function(e) {
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
    
    $(document).on('mouseup touchend', function(e) {
        if (!arrastrando) return;
        arrastrando = false;
        
        if (inicioY - (e.pageY || (e.originalEvent.changedTouches ? e.originalEvent.changedTouches[0].pageY : inicioY)) > 100) {
            desbloquearTablet();
        } else {
            $('.pantalla-bloqueo').css({'transform': 'translateY(0)', 'opacity': '1'});
        }
    });
    
    function desbloquearTablet() {
        bloqueado = false;
        reproducirSonido('apertura');
        $('.pantalla-bloqueo').css({'transform': 'translateY(-100%)', 'opacity': '0'});
        $('.pantalla-tablet').removeClass('bloqueado');
        setTimeout(() => {
            $('.pantalla-bloqueo').hide();
        }, 500);
    }
    
    $('.item-dock').on('click', function() {
        const id = $(this).attr('id');
        
        reproducirSonido('cambio');
        
        $('.item-dock').removeClass('activo');
        $(this).addClass('activo');
        
        $('.seccion-app').fadeOut(200);
        setTimeout(() => {
            let appId = id;
            if (id === 'dock-banco') {
                appId = 'banco';
            }
            $(`#app-${appId}`).fadeIn(200);
            
            if (id === 'dock-banco') {
                setTimeout(function() {
                    cargarBancoSimple();
                }, 100);
            } else if (id === 'facturas') {
                setTimeout(function() {
                    cargarFacturas();
                }, 100);
            }
        }, 200);
    });

    $(document).on('click', '#boton-transferir-banco', function() {
        reproducirSonido('click');
        $('#modal-transferir-banco').fadeIn(200);
    });

    $(document).on('click', '.cerrar-modal-banco', function() {
        reproducirSonido('click');
        const modal = $(this).data('modal');
        $(`#modal-${modal}-banco`).fadeOut(200);
    });

    $(document).on('click', '#confirmar-transferir-banco', function() {
        const cantidad = parseInt($('#entrada-transferir-cantidad').val());
        const idDestinatario = $('#entrada-transferir-id').val().trim();
        if (cantidad && cantidad > 0 && idDestinatario) {
            $.post('https://e-tablet/accionBanco', JSON.stringify({
                accion: 'transferir',
                cantidad: cantidad,
                idDestinatario: idDestinatario
            }), function(respuesta) {
                if (respuesta && respuesta.exito !== false) {
                    cargarBancoSimple();
                }
            });
            $('#modal-transferir-banco').fadeOut(200);
            $('#entrada-transferir-cantidad').val('');
            $('#entrada-transferir-id').val('');
            $('#confirmar-transferir-banco').prop('disabled', true);
        }
    });
    
    $(document).on('input', '#entrada-transferir-cantidad, #entrada-transferir-id', function() {
        const cantidad = $('#entrada-transferir-cantidad').val();
        const idDestinatario = $('#entrada-transferir-id').val().trim();
        $('#confirmar-transferir-banco').prop('disabled', !(cantidad && cantidad > 0 && idDestinatario));
    });

    $(document).on('input', '#entrada-busqueda-banco', function() {
        const terminoBusqueda = $(this).val().trim().toLowerCase();
        filtrarTransaccionesBanco(terminoBusqueda);
    });
    
    $(document).keyup(function(e) {
        if (e.keyCode == 27) {
            reproducirSonido('cierre');
            $('.contenedor-tablet').css('display', 'none');
            if (window.parent && window.parent !== window) {
                window.parent.postMessage({accion: 'cerrarTablet'}, '*');
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

window.addEventListener('message', function(event) {
    if (event.data.accion === 'abrir' && event.data.mostrar == true) {
        $('body').css('display', 'block')
        $('.contenedor-tablet').css('display', 'flex')
        
        $('.pagina-info').show();
        $('.pantalla-bloqueo').show().css({'transform': 'translateY(0)', 'opacity': '1'});
        $('.pantalla-tablet').addClass('bloqueado');
        
        $('.item-dock').removeClass('activo');
        $('#inicio').addClass('activo');
        $('.seccion-app').hide();
        $('#app-inicio').show();
        
        if (event.data.nombre) {
            $('.nombre').html(event.data.nombre);
        }
        
        if (event.data.trabajo) {
            $('#trabajo').html(event.data.trabajo);
        }
        
        if (event.data.grado) {
            $('#grado').html(' - ' + event.data.grado);
        }
        
        if (event.data.efectivo !== undefined) {
            $('#efectivo').html('$' + event.data.efectivo.toLocaleString());
        }
        
        if (event.data.banco !== undefined) {
            $('#banco').html('$' + event.data.banco.toLocaleString());
        }
        
        if (event.data.telefono) {
            $('#telefono').html(event.data.telefono);
        }
        
        if (event.data.ciudadano) {
            $('#ciudadano').html(event.data.ciudadano);
        }
        
        if (event.data.id !== undefined) {
            $('#id-jugador').html(event.data.id);
        }
        
        if (event.data.totalJugadores !== undefined) {
            $('#total-jugadores').html(event.data.totalJugadores);
        }
        
        if (event.data.headshot) {
            $('#foto-jugador').attr('src', 'https://nui-img/' + event.data.headshot + '/' + event.data.headshot);
        }
        
        if (event.data.policia !== undefined) {
            $('#conteo-policia').html(event.data.policia);
        }
        if (event.data.ems !== undefined) {
            $('#conteo-ems').html(event.data.ems);
        }
        if (event.data.mecanico !== undefined) {
            $('#conteo-mecanico').html(event.data.mecanico);
        }
        if (event.data.taxi !== undefined) {
            $('#conteo-taxi').html(event.data.taxi);
        }
    } else if (event.data.accion == 'cerrar' || event.data.mostrar == false) {
        reproducirSonido('cierre');
        $('.contenedor-tablet').css('display', 'none')
        $('body').css('display', 'none')
        $('#foto-jugador').attr('src', '');
    } else if (event.data.accion == 'notificacion') {
        mostrarNotificacion(event.data.tipo, event.data.mensaje);
    } else if (event.data.accion == 'actualizarSaldoBanco') {
        if (event.data.saldo !== undefined) {
            $('#banco').html('$' + event.data.saldo.toLocaleString());
        }
    }
});

let datosUsuarioBanco = {
    dineroBanco: 0,
    identificador: ''
};

let todasTransaccionesBanco = [];

function cargarBancoSimple() {
    if (typeof event !== 'undefined' && event.data && event.data.banco !== undefined) {
        datosUsuarioBanco.dineroBanco = event.data.banco || 0;
        datosUsuarioBanco.identificador = event.data.ciudadano || '';
        $('#saldo-banco').text('$' + datosUsuarioBanco.dineroBanco.toLocaleString());
    } else {
        $.post('https://e-tablet/obtenerDatosBanco', JSON.stringify({}), function(datos) {
            if (datos) {
                datosUsuarioBanco.dineroBanco = datos.dineroBanco || 0;
                datosUsuarioBanco.identificador = datos.identificador || '';
                $('#saldo-banco').text('$' + datosUsuarioBanco.dineroBanco.toLocaleString());
            }
        });
    }
    
    $.post('https://e-tablet/obtenerResumenBanco', JSON.stringify({}), function(datos) {
        const transacciones = datos.transacciones || [];
        todasTransaccionesBanco = transacciones;
        
        $('#entrada-busqueda-banco').val('');
        
        renderizarTransaccionesBanco(transacciones);
    }).fail(function() {
        $('#lista-transacciones-banco').html('<div class="transacciones-vacias-banco">Error al cargar movimientos</div>');
    });
}

function renderizarTransaccionesBanco(transacciones) {
    if (transacciones.length === 0) {
        $('#lista-transacciones-banco').html('<div class="transacciones-vacias-banco">No se encontraron movimientos</div>');
        return;
    }
    
    let htmlTransacciones = '';
    const num = transacciones.length > 10 ? 10 : transacciones.length;
    
    for (let i = 0; i < num; i++) {
        const t = transacciones[i];
        const tipo = t.type || 'transfer';
        const cantidad = parseFloat(t.value || 0);
        const esPositivo = tipo === 'deposit' || (tipo === 'transfer' && t.receiver_identifier === (datosUsuarioBanco.identificador || ''));
        const icono = esPositivo ? 'fa-arrow-down' : 'fa-arrow-up';
        const claseCantidad = esPositivo ? 'cantidad-positiva-banco' : 'cantidad-negativa-banco';
        const textoCantidad = esPositivo ? `+$${cantidad.toLocaleString()}` : `-$${Math.abs(cantidad).toLocaleString()}`;
        
        let textoTipo = '';
        if (tipo === 'deposit') textoTipo = 'Depósito';
        else if (tipo === 'withdraw') textoTipo = 'Retiro';
        else if (tipo === 'transfer') {
            if (t.receiver_identifier === (datosUsuarioBanco.identificador || '')) {
                textoTipo = `Transferencia de ${t.sender_name || 'Usuario'}`;
            } else {
                textoTipo = `Transferencia a ${t.receiver_name || 'Usuario'}`;
            }
        }
        
        const fecha = formatearFechaBanco(t.date);
        
        htmlTransacciones += `
            <div class="item-transaccion-banco">
                <div class="icono-transaccion-banco ${claseCantidad}">
                    <i class="fas ${icono}"></i>
                </div>
                <div class="info-transaccion-banco">
                    <div class="tipo-transaccion-banco">${textoTipo}</div>
                    <div class="fecha-transaccion-banco">${fecha}</div>
                </div>
                <div class="cantidad-transaccion-banco ${claseCantidad}">${textoCantidad}</div>
            </div>
        `;
    }
    
    $('#lista-transacciones-banco').html(htmlTransacciones);
}

function filtrarTransaccionesBanco(terminoBusqueda) {
    if (!terminoBusqueda) {
        renderizarTransaccionesBanco(todasTransaccionesBanco);
        return;
    }
    
    const filtradas = todasTransaccionesBanco.filter(t => {
        const cantidad = Math.abs(parseFloat(t.value || 0));
        const numeroBusqueda = parseFloat(terminoBusqueda);
        
        if (!isNaN(numeroBusqueda)) {
            return cantidad.toString().includes(terminoBusqueda) || 
                   cantidad === numeroBusqueda ||
                   Math.floor(cantidad) === Math.floor(numeroBusqueda);
        }
        
        const tipo = (t.type || '').toLowerCase();
        const textoTipo = tipo === 'deposit' ? 'depósito' : 
                       tipo === 'withdraw' ? 'retiro' : 
                       tipo === 'transfer' ? 'transferencia' : '';
        
        return textoTipo.includes(terminoBusqueda) || 
               cantidad.toString().includes(terminoBusqueda);
    });
    
    renderizarTransaccionesBanco(filtradas);
}

function formatearFechaBanco(timestamp) {
    if (!timestamp) return 'N/A';
    try {
        let objetoFecha;
        if (typeof timestamp === 'number' || (typeof timestamp === 'string' && /^\d+$/.test(timestamp))) {
            if (String(timestamp).length > 10) {
                objetoFecha = new Date(parseInt(timestamp));
            } else {
                objetoFecha = new Date(parseInt(timestamp) * 1000);
            }
        } else {
            objetoFecha = new Date(timestamp);
        }
        if (!isNaN(objetoFecha.getTime())) {
            const meses = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
            return `${objetoFecha.getDate()} ${meses[objetoFecha.getMonth()]} ${objetoFecha.getFullYear()}`;
        }
    } catch(e) {
        console.error("Error formateando fecha:", e);
    }
    return 'N/A';
}

function renderizarFacturas(facturas) {
    if (!facturas || facturas.length === 0) {
        $('#lista-facturas').html('<div class="estado-vacio"><i class="fas fa-check-circle"></i><p>No tienes facturas pendientes</p></div>');
        return;
    }
    
    let htmlFacturas = '';
    facturas.forEach(function(factura) {
        const cantidad = parseFloat(factura.amount || 0);
        const etiqueta = factura.label || factura.society || factura.sender || 'Factura';
        const id = factura.id || factura.billid || 0;
        
        htmlFacturas += `
            <div class="tarjeta-factura">
                <div class="info-factura">
                    <div class="etiqueta-factura">${etiqueta}</div>
                    <div class="cantidad-factura">$${cantidad.toLocaleString()}</div>
                </div>
                <button class="boton-pagar-factura" onclick="pagarFactura(${id})">
                    <i class="fas fa-check"></i>
                    Pagar
                </button>
            </div>
        `;
    });
    
    $('#lista-facturas').html(htmlFacturas);
}

function cargarFacturas() {
    $('#lista-facturas').html('<div class="estado-vacio"><i class="fas fa-spinner fa-spin"></i><p>Cargando facturas...</p></div>');
    
    $.post('https://e-tablet/obtenerFacturas', JSON.stringify({}), function(facturas) {
        renderizarFacturas(facturas);
    }).fail(function() {
        $('#lista-facturas').html('<div class="estado-vacio"><i class="fas fa-exclamation-circle"></i><p>Error al cargar facturas</p></div>');
    });
}

function pagarFactura(id) {
    reproducirSonido('click');
    $.post('https://e-tablet/pagarFactura', JSON.stringify({id: id}), function(respuesta) {
        if (respuesta && respuesta.exito !== false) {
            mostrarNotificacion('exito', 'Factura pagada exitosamente');
            cargarFacturas();
        } else {
            mostrarNotificacion('error', 'Error al pagar la factura');
        }
    }).fail(function() {
        mostrarNotificacion('error', 'Error al pagar la factura');
    });
}

window.pagarFactura = pagarFactura;

function mostrarNotificacion(tipo, mensaje) {
    const notificacion = $(`
        <div class="notificacion notificacion-${tipo}">
            <i class="fas fa-${tipo === 'exito' ? 'check-circle' : 'exclamation-circle'}"></i>
            <span>${mensaje}</span>
        </div>
    `);
    
    $('body').append(notificacion);
    
    setTimeout(() => {
        notificacion.addClass('mostrar');
    }, 100);
    
    setTimeout(() => {
        notificacion.removeClass('mostrar');
        setTimeout(() => {
            notificacion.remove();
        }, 300);
    }, 3000);
}
