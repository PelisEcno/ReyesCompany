package com.reyescompany.app.repository;

import com.reyescompany.app.model.Venta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface VentaRepository extends JpaRepository<Venta, Integer> {

    @Query("SELECT v FROM Venta v " +
           "JOIN FETCH v.usuario " +
           "JOIN FETCH v.sucursal " +
           "JOIN FETCH v.cliente")
    List<Venta> listarConDatos();
}
