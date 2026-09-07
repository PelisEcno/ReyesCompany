package com.reyescompany.app.service;

import com.reyescompany.app.model.Venta;
import com.reyescompany.app.repository.VentaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class VentaService {

    @Autowired
    private VentaRepository ventaRepository;

    public List<Venta> listar() {
        return ventaRepository.findAll();
    }

    public Venta buscarPorId(Integer id) {
        return ventaRepository.findById(id).orElse(null);
    }

    public Venta guardar(Venta venta) {
        if (venta.getIdVenta() != null) {
            Venta existente = ventaRepository.findById(venta.getIdVenta()).orElse(null);
            if (existente != null) {
                venta.setCreatedAt(existente.getCreatedAt());
            }
        } else {
            venta.setCreatedAt(LocalDateTime.now());
        }
        venta.setUpdatedAt(LocalDateTime.now());
        return ventaRepository.save(venta);
    }

    public void eliminar(Integer id) {
        ventaRepository.deleteById(id);
    }
}
