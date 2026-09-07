package com.reyescompany.app.service;

import com.reyescompany.app.model.Cliente;
import com.reyescompany.app.model.DeudaCliente;
import com.reyescompany.app.model.DetalleVenta;
import com.reyescompany.app.model.Inventario;
import com.reyescompany.app.model.ItemVentaRequest;
import com.reyescompany.app.model.MetodoPago;
import com.reyescompany.app.model.Pago;
import com.reyescompany.app.model.Sucursal;
import com.reyescompany.app.model.Usuario;
import com.reyescompany.app.model.Venta;
import com.reyescompany.app.model.VentaRequest;
import com.reyescompany.app.repository.ClienteRepository;
import com.reyescompany.app.repository.DeudaClienteRepository;
import com.reyescompany.app.repository.DetalleVentaRepository;
import com.reyescompany.app.repository.InventarioRepository;
import com.reyescompany.app.repository.MetodoPagoRepository;
import com.reyescompany.app.repository.PagoRepository;
import com.reyescompany.app.repository.SucursalRepository;
import com.reyescompany.app.repository.UsuarioRepository;
import com.reyescompany.app.repository.VentaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class VentaService {

    @Autowired
    private VentaRepository ventaRepository;

    @Autowired
    private InventarioRepository inventarioRepository;

    @Autowired
    private DetalleVentaRepository detalleVentaRepository;

    @Autowired
    private PagoRepository pagoRepository;

    @Autowired
    private DeudaClienteRepository deudaClienteRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private SucursalRepository sucursalRepository;

    @Autowired
    private ClienteRepository clienteRepository;

    @Autowired
    private MetodoPagoRepository metodoPagoRepository;

    public List<Venta> listar() {
        return ventaRepository.findAll();
    }

    public Venta buscarPorId(Integer id) {
        return ventaRepository.findById(id).orElse(null);
    }

    public Venta guardar(Venta venta) {
        if (venta.getIdVenta() != null) {
            Venta existente = ventaRepository.findById(venta.getIdVenta()).orElse(null);
            if (existente != null) {
                venta.setCreatedAt(existente.getCreatedAt());
            }
        } else {
            venta.setCreatedAt(LocalDateTime.now());
        }
        venta.setUpdatedAt(LocalDateTime.now());
        return ventaRepository.save(venta);
    }

    public void eliminar(Integer id) {
        ventaRepository.deleteById(id);
    }

    @Transactional
    public Venta registrarVenta(VentaRequest request) {
        Usuario usuario = usuarioRepository.findById(request.getIdUsuario()).orElseThrow();
        Sucursal sucursal = sucursalRepository.findById(request.getIdSucursal()).orElseThrow();
        Cliente cliente = clienteRepository.findById(request.getIdCliente()).orElseThrow();

        BigDecimal total = BigDecimal.ZERO;

        for (ItemVentaRequest item : request.getItems()) {
            Inventario inventario = inventarioRepository.findById(item.getIdInventario()).orElseThrow();
            if (inventario.getStock() < item.getCantidad()) {
                throw new RuntimeException("Stock insuficiente para " + inventario.getProducto().getNombre());
            }
            BigDecimal subtotal = item.getPrecioUnitario().multiply(BigDecimal.valueOf(item.getCantidad()));
            total = total.add(subtotal);
        }

        Venta venta = new Venta();
        venta.setFecha(LocalDate.now());
        venta.setTotal(total);
        venta.setUsuario(usuario);
        venta.setSucursal(sucursal);
        venta.setCliente(cliente);
        venta.setCreatedAt(LocalDateTime.now());
        venta.setUpdatedAt(LocalDateTime.now());
        venta = ventaRepository.save(venta);

        for (ItemVentaRequest item : request.getItems()) {
            Inventario inventario = inventarioRepository.findById(item.getIdInventario()).orElseThrow();
            inventario.setStock(inventario.getStock() - item.getCantidad());
            inventario.setUpdatedAt(LocalDateTime.now());
            inventarioRepository.save(inventario);

            DetalleVenta detalle = new DetalleVenta();
            detalle.setVenta(venta);
            detalle.setInventario(inventario);
            detalle.setCantidad(item.getCantidad());
            detalle.setPrecioUnitario(item.getPrecioUnitario());
            detalleVentaRepository.save(detalle);
        }

        if (Boolean.TRUE.equals(request.getEsFiado())) {
            DeudaCliente deuda = new DeudaCliente();
            deuda.setCliente(cliente);
            deuda.setVenta(venta);
            deuda.setFechaDeuda(LocalDateTime.now());
            deuda.setUpdatedAt(LocalDateTime.now());
            deudaClienteRepository.save(deuda);
        } else {
            MetodoPago metodoPago = metodoPagoRepository.findById(request.getIdMetodoPago()).orElseThrow();
            Pago pago = new Pago();
            pago.setMonto(total);
            pago.setFecha(LocalDate.now());
            pago.setMetodoPago(metodoPago);
            pago.setVenta(venta);
            pagoRepository.save(pago);
        }

        return venta;
    }
}
