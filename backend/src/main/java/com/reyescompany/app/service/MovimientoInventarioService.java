package com.reyescompany.app.service;

import com.reyescompany.app.model.MovimientoInventario;
import com.reyescompany.app.repository.MovimientoInventarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class MovimientoInventarioService {

    @Autowired
    private MovimientoInventarioRepository movimientoInventarioRepository;

    public List<MovimientoInventario> listar() {
        return movimientoInventarioRepository.findAll();
    }

    public MovimientoInventario buscarPorId(Integer id) {
        return movimientoInventarioRepository.findById(id).orElse(null);
    }

    public MovimientoInventario guardar(MovimientoInventario movimientoInventario) {
        return movimientoInventarioRepository.save(movimientoInventario);
    }

    public void eliminar(Integer id) {
        movimientoInventarioRepository.deleteById(id);
    }
}
