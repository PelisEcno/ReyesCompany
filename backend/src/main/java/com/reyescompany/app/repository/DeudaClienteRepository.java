package com.reyescompany.app.repository;

import com.reyescompany.app.model.DeudaCliente;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeudaClienteRepository extends JpaRepository<DeudaCliente, Integer> {
}
