package com.reyescompany.app.service;

import com.reyescompany.app.model.MetodoPago;
import com.reyescompany.app.repository.MetodoPagoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class MetodoPagoService {

    @Autowired
    private MetodoPagoRepository metodoPagoRepository;

    public List<MetodoPago> listar() {
        return metodoPagoRepository.findAll();
    }

    public MetodoPago buscarPorId(Integer id) {
        return metodoPagoRepository.findById(id).orElse(null);
    }

    public MetodoPago guardar(MetodoPago metodoPago) {
        return metodoPagoRepository.save(metodoPago);
    }

    public void eliminar(Integer id) {
        metodoPagoRepository.deleteById(id);
    }
}
