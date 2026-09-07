package com.reyescompany.app.service;

import com.reyescompany.app.model.DetalleVenta;
import com.reyescompany.app.repository.DetalleVentaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class DetalleVentaService {

    @Autowired
    private DetalleVentaRepository detalleVentaRepository;

    public List<DetalleVenta> listar() {
        return detalleVentaRepository.findAll();
    }

    public DetalleVenta buscarPorId(Integer id) {
        return detalleVentaRepository.findById(id).orElse(null);
    }

    public DetalleVenta guardar(DetalleVenta detalleVenta) {
        return detalleVentaRepository.save(detalleVenta);
    }

    public void eliminar(Integer id) {
        detalleVentaRepository.deleteById(id);
    }
}
