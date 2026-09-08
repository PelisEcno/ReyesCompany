package com.reyescompany.app.repository;

import com.reyescompany.app.model.Inventario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface InventarioRepository extends JpaRepository<Inventario, Integer> {

    @Query("SELECT i FROM Inventario i " +
           "JOIN FETCH i.producto p " +
           "JOIN FETCH p.categoria " +
           "JOIN FETCH i.sucursal")
    List<Inventario> listarConDatos();
}
