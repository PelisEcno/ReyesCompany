package com.reyescompany.app.repository;

import com.reyescompany.app.model.MovimientoInventario;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MovimientoInventarioRepository extends JpaRepository<MovimientoInventario, Integer> {
}
