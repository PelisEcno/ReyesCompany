package com.reyescompany.app.repository;

import com.reyescompany.app.model.Producto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface ProductoRepository extends JpaRepository<Producto, Integer> {

    @Query("SELECT p FROM Producto p JOIN FETCH p.categoria")
    List<Producto> listarConDatos();
}
