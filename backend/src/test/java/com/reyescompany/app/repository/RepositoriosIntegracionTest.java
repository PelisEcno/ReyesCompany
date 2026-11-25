package com.reyescompany.app.repository;

import com.reyescompany.app.model.Categoria;
import com.reyescompany.app.model.Inventario;
import com.reyescompany.app.model.MovimientoInventario;
import com.reyescompany.app.model.Producto;
import com.reyescompany.app.model.Sucursal;
import com.reyescompany.app.model.TipoMovimiento;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

@DataJpaTest
public class RepositoriosIntegracionTest {

    @Autowired
    private TestEntityManager entityManager;

    @Autowired
    private VentaRepository ventaRepository;

    @Autowired
    private InventarioRepository inventarioRepository;

    @Autowired
    private ProductoRepository productoRepository;

    @Autowired
    private DeudaClienteRepository deudaClienteRepository;

    @Autowired
    private AbonoRepository abonoRepository;

    @Autowired
    private PagoRepository pagoRepository;

    @Autowired
    private DetalleVentaRepository detalleVentaRepository;

    @Autowired
    private MovimientoInventarioRepository movimientoInventarioRepository;

    @Autowired
    private TipoMovimientoRepository tipoMovimientoRepository;

    @Test
    public void lasConsultasConJoinFetchSeEjecutanSinError() {
        assertTrue(ventaRepository.listarConDatos().isEmpty());
        assertTrue(inventarioRepository.listarConDatos().isEmpty());
        assertTrue(productoRepository.listarConDatos().isEmpty());
        assertTrue(deudaClienteRepository.listarConDatos().isEmpty());
        assertTrue(abonoRepository.listarConDatos().isEmpty());
        assertTrue(pagoRepository.listarConDatos().isEmpty());
        assertTrue(detalleVentaRepository.listarConDatos().isEmpty());
        assertTrue(movimientoInventarioRepository.listarConDatos().isEmpty());
    }

    @Test
    public void lasBusquedasPorVentaSeEjecutanSinError() {
        assertTrue(detalleVentaRepository.findByVentaIdVenta(1).isEmpty());
        assertTrue(pagoRepository.findByVentaIdVenta(1).isEmpty());
        assertTrue(deudaClienteRepository.findByVentaIdVenta(1).isEmpty());
        assertTrue(movimientoInventarioRepository.findByVentaIdVenta(1).isEmpty());
        assertTrue(abonoRepository.findByDeudaClienteIdDeudaCliente(1).isEmpty());
        assertNull(tipoMovimientoRepository.findFirstByNombre("NoExiste"));
    }

    @Test
    public void unMovimientoSinVentaNiUsuarioSeGuardaYSeListaConSusRelaciones() {
        Categoria categoria = new Categoria();
        categoria.setNombre("Bebidas");
        entityManager.persist(categoria);

        Producto producto = new Producto();
        producto.setNombre("Coca Cola 400ml");
        producto.setDescripcion("Gaseosa personal");
        producto.setPrecioCompra(new BigDecimal("3000"));
        producto.setPrecioVenta(new BigDecimal("4500"));
        producto.setCreatedAt(LocalDateTime.now());
        producto.setUpdatedAt(LocalDateTime.now());
        producto.setCategoria(categoria);
        entityManager.persist(producto);

        Sucursal sucursal = new Sucursal();
        sucursal.setNombre("Sucursal Principal");
        sucursal.setDireccion("Calle 10 #5-20");
        sucursal.setTelefono("3001112233");
        entityManager.persist(sucursal);

        Inventario inventario = new Inventario();
        inventario.setStock(10);
        inventario.setStockMinimo(5);
        inventario.setCreatedAt(LocalDateTime.now());
        inventario.setUpdatedAt(LocalDateTime.now());
        inventario.setProducto(producto);
        inventario.setSucursal(sucursal);
        entityManager.persist(inventario);

        TipoMovimiento tipo = new TipoMovimiento();
        tipo.setNombre("Merma");
        entityManager.persist(tipo);

        MovimientoInventario movimiento = new MovimientoInventario();
        movimiento.setCantidad(2);
        movimiento.setFecha(LocalDateTime.now());
        movimiento.setObservacion("Producto vencido");
        movimiento.setTipoMovimiento(tipo);
        movimiento.setInventario(inventario);
        movimientoInventarioRepository.save(movimiento);

        entityManager.flush();
        entityManager.clear();

        List<MovimientoInventario> lista = movimientoInventarioRepository.listarConDatos();

        assertEquals(1, lista.size());
        assertNull(lista.get(0).getVenta());
        assertNull(lista.get(0).getUsuario());
        assertEquals("Merma", lista.get(0).getTipoMovimiento().getNombre());
        assertEquals("Coca Cola 400ml", lista.get(0).getInventario().getProducto().getNombre());
        assertEquals("Producto vencido", lista.get(0).getObservacion());
        assertEquals(1, inventarioRepository.listarConDatos().size());
        assertEquals(1, productoRepository.listarConDatos().size());
        assertNotNull(tipoMovimientoRepository.findFirstByNombre("Merma"));
    }
}
