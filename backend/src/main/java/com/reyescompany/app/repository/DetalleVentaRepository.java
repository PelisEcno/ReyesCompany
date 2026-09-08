package com.reyescompany.app.repository;

import com.reyescompany.app.model.DetalleVenta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface DetalleVentaRepository extends JpaRepository<DetalleVenta, Integer> {

    @Query("SELECT dv FROM DetalleVenta dv " +
           "JOIN FETCH dv.inventario i " +
           "JOIN FETCH i.producto " +
           "JOIN FETCH i.sucursal " +
           "JOIN FETCH dv.venta")
    List<DetalleVenta> listarConDatos();
}
