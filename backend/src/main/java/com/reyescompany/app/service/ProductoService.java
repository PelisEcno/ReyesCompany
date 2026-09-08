package com.reyescompany.app.service;

import com.reyescompany.app.model.Producto;
import com.reyescompany.app.repository.ProductoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class ProductoService {

    @Autowired
    private ProductoRepository productoRepository;

    public List<Producto> listar() {
        return productoRepository.listarConDatos();
    }

    public Producto buscarPorId(Integer id) {
        return productoRepository.findById(id).orElse(null);
    }

    public Producto guardar(Producto producto) {
        if (producto.getIdProducto() != null) {
            Producto existente = productoRepository.findById(producto.getIdProducto()).orElse(null);
            if (existente != null) {
                producto.setCreatedAt(existente.getCreatedAt());
            }
        } else {
            producto.setCreatedAt(LocalDateTime.now());
        }
        producto.setUpdatedAt(LocalDateTime.now());
        return productoRepository.save(producto);
    }

    public void eliminar(Integer id) {
        productoRepository.deleteById(id);
    }
}
