package com.reyescompany.app.service;

import com.reyescompany.app.model.Inventario;
import com.reyescompany.app.repository.InventarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class InventarioService {

    @Autowired
    private InventarioRepository inventarioRepository;

    public List<Inventario> listar() {
        return inventarioRepository.listarConDatos();
    }

    public Inventario buscarPorId(Integer id) {
        return inventarioRepository.findById(id).orElse(null);
    }

    public Inventario guardar(Inventario inventario) {
        if (inventario.getIdInventario() != null) {
            Inventario existente = inventarioRepository.findById(inventario.getIdInventario()).orElse(null);
            if (existente != null) {
                inventario.setCreatedAt(existente.getCreatedAt());
            }
        } else {
            inventario.setCreatedAt(LocalDateTime.now());
        }
        inventario.setUpdatedAt(LocalDateTime.now());
        return inventarioRepository.save(inventario);
    }

    public void eliminar(Integer id) {
        inventarioRepository.deleteById(id);
    }
}
