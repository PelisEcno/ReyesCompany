package com.reyescompany.app.service;

import com.reyescompany.app.model.Abono;
import com.reyescompany.app.model.Cliente;
import com.reyescompany.app.model.DeudaCliente;
import com.reyescompany.app.model.DetalleVenta;
import com.reyescompany.app.model.Inventario;
import com.reyescompany.app.model.ItemVentaRequest;
import com.reyescompany.app.model.MetodoPago;
import com.reyescompany.app.model.Pago;
import com.reyescompany.app.model.Producto;
import com.reyescompany.app.model.Sucursal;
import com.reyescompany.app.model.Usuario;
import com.reyescompany.app.model.Venta;
import com.reyescompany.app.model.VentaRequest;
import com.reyescompany.app.repository.AbonoRepository;
import com.reyescompany.app.repository.ClienteRepository;
import com.reyescompany.app.repository.DeudaClienteRepository;
import com.reyescompany.app.repository.DetalleVentaRepository;
import com.reyescompany.app.repository.InventarioRepository;
import com.reyescompany.app.repository.MetodoPagoRepository;
import com.reyescompany.app.repository.PagoRepository;
import com.reyescompany.app.repository.SucursalRepository;
import com.reyescompany.app.repository.UsuarioRepository;
import com.reyescompany.app.repository.VentaRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class VentaServiceTest {

    @Mock
    private VentaRepository ventaRepository;

    @Mock
    private InventarioRepository inventarioRepository;

    @Mock
    private DetalleVentaRepository detalleVentaRepository;

    @Mock
    private PagoRepository pagoRepository;

    @Mock
    private DeudaClienteRepository deudaClienteRepository;

    @Mock
    private UsuarioRepository usuarioRepository;

    @Mock
    private SucursalRepository sucursalRepository;

    @Mock
    private ClienteRepository clienteRepository;

    @Mock
    private MetodoPagoRepository metodoPagoRepository;

    @Mock
    private AbonoRepository abonoRepository;

    @Mock
    private MovimientoInventarioService movimientoInventarioService;

    @InjectMocks
    private VentaService ventaService;

    private VentaRequest crearRequest(int cantidad, boolean fiado) {
        ItemVentaRequest item = new ItemVentaRequest();
        item.setIdInventario(1);
        item.setCantidad(cantidad);
        item.setPrecioUnitario(new BigDecimal("4500"));

        VentaRequest request = new VentaRequest();
        request.setIdUsuario(1);
        request.setIdSucursal(1);
        request.setIdCliente(1);
        request.setIdMetodoPago(1);
        request.setEsFiado(fiado);
        request.setItems(List.of(item));
        return request;
    }

    private Inventario crearInventario(int stock) {
        Producto producto = new Producto();
        producto.setNombre("Coca Cola 400ml");

        Inventario inventario = new Inventario();
        inventario.setIdInventario(1);
        inventario.setStock(stock);
        inventario.setProducto(producto);
        return inventario;
    }

    private void prepararDatosBasicos(Inventario inventario) {
        when(usuarioRepository.findById(1)).thenReturn(Optional.of(new Usuario()));
        when(sucursalRepository.findById(1)).thenReturn(Optional.of(new Sucursal()));
        when(clienteRepository.findById(1)).thenReturn(Optional.of(new Cliente()));
        when(inventarioRepository.findById(1)).thenReturn(Optional.of(inventario));
    }

    @Test
    public void ventaConStockInsuficienteLanzaExcepcionYNoGuardaNada() {
        Inventario inventario = crearInventario(1);
        prepararDatosBasicos(inventario);

        assertThrows(RuntimeException.class, () -> ventaService.registrarVenta(crearRequest(5, false)));

        assertEquals(1, inventario.getStock());
        verify(ventaRepository, never()).save(any(Venta.class));
        verify(pagoRepository, never()).save(any(Pago.class));
        verify(deudaClienteRepository, never()).save(any(DeudaCliente.class));
    }

    @Test
    public void ventaDeContadoCalculaElTotalDescuentaElStockYCreaElPago() {
        Inventario inventario = crearInventario(10);
        prepararDatosBasicos(inventario);
        when(metodoPagoRepository.findById(1)).thenReturn(Optional.of(new MetodoPago()));
        when(ventaRepository.save(any(Venta.class))).thenAnswer(inv -> inv.getArgument(0));

        Venta venta = ventaService.registrarVenta(crearRequest(2, false));

        assertEquals(0, new BigDecimal("9000").compareTo(venta.getTotal()));
        assertEquals(8, inventario.getStock());
        verify(detalleVentaRepository, times(1)).save(any(DetalleVenta.class));
        verify(deudaClienteRepository, never()).save(any(DeudaCliente.class));
        verify(movimientoInventarioService, times(1)).guardarMovimiento(eq("Venta"), eq(inventario), eq(2), eq(venta), any(Usuario.class), isNull());

        ArgumentCaptor<Pago> captor = ArgumentCaptor.forClass(Pago.class);
        verify(pagoRepository, times(1)).save(captor.capture());
        assertEquals(0, new BigDecimal("9000").compareTo(captor.getValue().getMonto()));
    }

    @Test
    public void ventaFiadaCreaLaDeudaDelClienteYNoCreaPago() {
        Inventario inventario = crearInventario(10);
        prepararDatosBasicos(inventario);
        when(ventaRepository.save(any(Venta.class))).thenAnswer(inv -> inv.getArgument(0));

        Venta venta = ventaService.registrarVenta(crearRequest(3, true));

        assertEquals(0, new BigDecimal("13500").compareTo(venta.getTotal()));
        assertEquals(7, inventario.getStock());
        verify(deudaClienteRepository, times(1)).save(any(DeudaCliente.class));
        verify(pagoRepository, never()).save(any(Pago.class));
    }

    @Test
    public void anularVentaDevuelveElStockYBorraLaVenta() {
        Inventario inventario = crearInventario(8);
        DetalleVenta detalle = new DetalleVenta();
        detalle.setInventario(inventario);
        detalle.setCantidad(2);
        Venta venta = new Venta();
        venta.setIdVenta(50);
        when(ventaRepository.findById(50)).thenReturn(Optional.of(venta));
        when(detalleVentaRepository.findByVentaIdVenta(50)).thenReturn(List.of(detalle));
        when(pagoRepository.findByVentaIdVenta(50)).thenReturn(List.of());
        when(deudaClienteRepository.findByVentaIdVenta(50)).thenReturn(List.of());

        ventaService.anularVenta(50);

        assertEquals(10, inventario.getStock());
        verify(movimientoInventarioService, times(1)).eliminarPorVenta(50);
        verify(detalleVentaRepository, times(1)).deleteAll(List.of(detalle));
        verify(ventaRepository, times(1)).delete(venta);
    }

    @Test
    public void anularVentaFiadaBorraTambienLosAbonosYLaDeuda() {
        Venta venta = new Venta();
        venta.setIdVenta(51);
        DeudaCliente deuda = new DeudaCliente();
        deuda.setIdDeudaCliente(7);
        Abono abono = new Abono();
        when(ventaRepository.findById(51)).thenReturn(Optional.of(venta));
        when(detalleVentaRepository.findByVentaIdVenta(51)).thenReturn(List.of());
        when(pagoRepository.findByVentaIdVenta(51)).thenReturn(List.of());
        when(deudaClienteRepository.findByVentaIdVenta(51)).thenReturn(List.of(deuda));
        when(abonoRepository.findByDeudaClienteIdDeudaCliente(7)).thenReturn(List.of(abono));

        ventaService.anularVenta(51);

        verify(abonoRepository, times(1)).deleteAll(List.of(abono));
        verify(deudaClienteRepository, times(1)).deleteAll(List.of(deuda));
        verify(ventaRepository, times(1)).delete(venta);
    }

    @Test
    public void anularVentaInexistenteLanzaExcepcionYNoBorraNada() {
        when(ventaRepository.findById(99)).thenReturn(Optional.empty());

        assertThrows(RuntimeException.class, () -> ventaService.anularVenta(99));

        verify(ventaRepository, never()).delete(any(Venta.class));
    }
}
