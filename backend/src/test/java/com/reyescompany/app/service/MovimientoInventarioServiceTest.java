package com.reyescompany.app.service;

import com.reyescompany.app.model.Inventario;
import com.reyescompany.app.model.MovimientoInventario;
import com.reyescompany.app.model.MovimientoRequest;
import com.reyescompany.app.model.TipoMovimiento;
import com.reyescompany.app.repository.InventarioRepository;
import com.reyescompany.app.repository.MovimientoInventarioRepository;
import com.reyescompany.app.repository.TipoMovimientoRepository;
import com.reyescompany.app.repository.UsuarioRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class MovimientoInventarioServiceTest {

    @Mock
    private MovimientoInventarioRepository movimientoInventarioRepository;

    @Mock
    private InventarioRepository inventarioRepository;

    @Mock
    private TipoMovimientoRepository tipoMovimientoRepository;

    @Mock
    private UsuarioRepository usuarioRepository;

    @InjectMocks
    private MovimientoInventarioService movimientoInventarioService;

    private Inventario crearInventario(int stock) {
        Inventario inventario = new Inventario();
        inventario.setIdInventario(1);
        inventario.setStock(stock);
        return inventario;
    }

    private MovimientoRequest crearRequest(String tipo, int cantidad, String observacion) {
        MovimientoRequest request = new MovimientoRequest();
        request.setIdInventario(1);
        request.setTipo(tipo);
        request.setCantidad(cantidad);
        request.setObservacion(observacion);
        return request;
    }

    @Test
    public void entradaSumaElStockYGuardaElMovimiento() {
        Inventario inventario = crearInventario(10);
        when(inventarioRepository.findById(1)).thenReturn(Optional.of(inventario));
        when(tipoMovimientoRepository.findFirstByNombre("Entrada")).thenReturn(new TipoMovimiento());
        when(movimientoInventarioRepository.save(any(MovimientoInventario.class))).thenAnswer(inv -> inv.getArgument(0));

        MovimientoInventario movimiento = movimientoInventarioService.registrarMovimiento(crearRequest("Entrada", 5, "Compra al proveedor"));

        assertEquals(15, inventario.getStock());
        assertEquals(5, movimiento.getCantidad());
        assertEquals("Compra al proveedor", movimiento.getObservacion());
        assertNull(movimiento.getVenta());
    }

    @Test
    public void mermaRestaElStockYGuardaElMovimiento() {
        Inventario inventario = crearInventario(10);
        when(inventarioRepository.findById(1)).thenReturn(Optional.of(inventario));
        when(tipoMovimientoRepository.findFirstByNombre("Merma")).thenReturn(new TipoMovimiento());
        when(movimientoInventarioRepository.save(any(MovimientoInventario.class))).thenAnswer(inv -> inv.getArgument(0));

        MovimientoInventario movimiento = movimientoInventarioService.registrarMovimiento(crearRequest("Merma", 3, "Producto vencido"));

        assertEquals(7, inventario.getStock());
        assertEquals(3, movimiento.getCantidad());
    }

    @Test
    public void mermaMayorAlStockLanzaExcepcionYNoGuardaNada() {
        Inventario inventario = crearInventario(2);
        when(inventarioRepository.findById(1)).thenReturn(Optional.of(inventario));

        assertThrows(RuntimeException.class, () -> movimientoInventarioService.registrarMovimiento(crearRequest("Merma", 5, null)));

        assertEquals(2, inventario.getStock());
        verify(movimientoInventarioRepository, never()).save(any(MovimientoInventario.class));
    }

    @Test
    public void cantidadEnCeroLanzaExcepcion() {
        assertThrows(RuntimeException.class, () -> movimientoInventarioService.registrarMovimiento(crearRequest("Entrada", 0, null)));
    }

    @Test
    public void tipoDeMovimientoInvalidoLanzaExcepcion() {
        Inventario inventario = crearInventario(10);
        when(inventarioRepository.findById(1)).thenReturn(Optional.of(inventario));

        assertThrows(RuntimeException.class, () -> movimientoInventarioService.registrarMovimiento(crearRequest("Regalo", 1, null)));

        assertEquals(10, inventario.getStock());
    }

    @Test
    public void elTipoDeMovimientoSeCreaSiNoExiste() {
        when(tipoMovimientoRepository.findFirstByNombre("Merma")).thenReturn(null);
        when(tipoMovimientoRepository.save(any(TipoMovimiento.class))).thenAnswer(inv -> inv.getArgument(0));

        TipoMovimiento tipo = movimientoInventarioService.obtenerTipo("Merma");

        assertEquals("Merma", tipo.getNombre());
        verify(tipoMovimientoRepository, times(1)).save(any(TipoMovimiento.class));
    }
}
