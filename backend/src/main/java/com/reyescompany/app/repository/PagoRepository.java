package com.reyescompany.app.repository;

import com.reyescompany.app.model.Pago;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface PagoRepository extends JpaRepository<Pago, Integer> {

    @Query("SELECT p FROM Pago p " +
           "JOIN FETCH p.metodoPago " +
           "JOIN FETCH p.venta")
    List<Pago> listarConDatos();
}
