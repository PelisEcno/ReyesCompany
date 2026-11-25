package com.reyescompany.app.repository;

import com.reyescompany.app.model.MovimientoInventario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface MovimientoInventarioRepository extends JpaRepository<MovimientoInventario, Integer> {

    @Query("SELECT m FROM MovimientoInventario m " +
           "JOIN FETCH m.tipoMovimiento " +
           "JOIN FETCH m.inventario i " +
           "JOIN FETCH i.producto p " +
           "JOIN FETCH p.categoria " +
           "JOIN FETCH i.sucursal " +
           "LEFT JOIN FETCH m.usuario u " +
           "LEFT JOIN FETCH u.rol " +
           "LEFT JOIN FETCH m.venta " +
           "ORDER BY m.fecha DESC")
    List<MovimientoInventario> listarConDatos();

    List<MovimientoInventario> findByVentaIdVenta(Integer idVenta);
}
