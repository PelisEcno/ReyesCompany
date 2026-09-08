package com.reyescompany.app.repository;

import com.reyescompany.app.model.DeudaCliente;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface DeudaClienteRepository extends JpaRepository<DeudaCliente, Integer> {

    @Query("SELECT d FROM DeudaCliente d " +
           "JOIN FETCH d.cliente " +
           "JOIN FETCH d.venta v " +
           "JOIN FETCH v.sucursal")
    List<DeudaCliente> listarConDatos();
}
