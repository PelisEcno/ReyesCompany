package com.reyescompany.app.repository;

import com.reyescompany.app.model.Abono;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface AbonoRepository extends JpaRepository<Abono, Integer> {

    @Query("SELECT a FROM Abono a " +
           "JOIN FETCH a.deudaCliente d " +
           "JOIN FETCH d.cliente " +
           "JOIN FETCH d.venta")
    List<Abono> listarConDatos();
}
