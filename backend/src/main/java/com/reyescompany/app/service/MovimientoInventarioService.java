package com.reyescompany.app.service;

import com.reyescompany.app.model.Inventario;
import com.reyescompany.app.model.MovimientoInventario;
import com.reyescompany.app.model.MovimientoRequest;
import com.reyescompany.app.model.TipoMovimiento;
import com.reyescompany.app.model.Usuario;
import com.reyescompany.app.model.Venta;
import com.reyescompany.app.repository.InventarioRepository;
import com.reyescompany.app.repository.MovimientoInventarioRepository;
import com.reyescompany.app.repository.TipoMovimientoRepository;
import com.reyescompany.app.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class MovimientoInventarioService {

    @Autowired
    private MovimientoInventarioRepository movimientoInventarioRepository;

    @Autowired
    private InventarioRepository inventarioRepository;

    @Autowired
    private TipoMovimientoRepository tipoMovimientoRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    public List<MovimientoInventario> listar() {
        return movimientoInventarioRepository.listarConDatos();
    }

    public MovimientoInventario buscarPorId(Integer id) {
        return movimientoInventarioRepository.findById(id).orElse(null);
    }

    public MovimientoInventario guardar(MovimientoInventario movimientoInventario) {
        if (movimientoInventario.getFecha() == null) {
            movimientoInventario.setFecha(LocalDateTime.now());
        }
        return movimientoInventarioRepository.save(movimientoInventario);
    }

    public void eliminar(Integer id) {
        movimientoInventarioRepository.deleteById(id);
    }

    public TipoMovimiento obtenerTipo(String nombre) {
        TipoMovimiento tipo = tipoMovimientoRepository.findFirstByNombre(nombre);
        if (tipo == null) {
            tipo = new TipoMovimiento();
            tipo.setNombre(nombre);
            tipo = tipoMovimientoRepository.save(tipo);
        }
        return tipo;
    }

    public MovimientoInventario guardarMovimiento(String nombreTipo, Inventario inventario, Integer cantidad,
                                                  Venta venta, Usuario usuario, String observacion) {
        MovimientoInventario movimiento = new MovimientoInventario();
        movimiento.setTipoMovimiento(obtenerTipo(nombreTipo));
        movimiento.setInventario(inventario);
        movimiento.setCantidad(cantidad);
        movimiento.setFecha(LocalDateTime.now());
        movimiento.setVenta(venta);
        movimiento.setUsuario(usuario);
        movimiento.setObservacion(observacion);
        return movimientoInventarioRepository.save(movimiento);
    }

    @Transactional
    public MovimientoInventario registrarMovimiento(MovimientoRequest request) {
        if (request.getCantidad() == null || request.getCantidad() <= 0) {
            throw new RuntimeException("La cantidad debe ser mayor a cero");
        }
        if (request.getTipo() == null) {
            throw new RuntimeException("Debes indicar el tipo de movimiento");
        }

        Inventario inventario = inventarioRepository.findById(request.getIdInventario()).orElseThrow();

        if (request.getTipo().equals("Entrada")) {
            inventario.setStock(inventario.getStock() + request.getCantidad());
        } else if (request.getTipo().equals("Merma")) {
            if (inventario.getStock() < request.getCantidad()) {
                throw new RuntimeException("La merma no puede ser mayor al stock actual (" + inventario.getStock() + ")");
            }
            inventario.setStock(inventario.getStock() - request.getCantidad());
        } else {
            throw new RuntimeException("Tipo de movimiento no valido: " + request.getTipo());
        }
        inventario.setUpdatedAt(LocalDateTime.now());
        inventarioRepository.save(inventario);

        Usuario usuario = null;
        if (request.getIdUsuario() != null) {
            usuario = usuarioRepository.findById(request.getIdUsuario()).orElse(null);
        }

        return guardarMovimiento(request.getTipo(), inventario, request.getCantidad(), null, usuario, request.getObservacion());
    }

    public void eliminarPorVenta(Integer idVenta) {
        movimientoInventarioRepository.deleteAll(movimientoInventarioRepository.findByVentaIdVenta(idVenta));
    }
}
