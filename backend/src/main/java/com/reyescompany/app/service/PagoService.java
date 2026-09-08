package com.reyescompany.app.service;

import com.reyescompany.app.model.Pago;
import com.reyescompany.app.repository.PagoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PagoService {

    @Autowired
    private PagoRepository pagoRepository;

    public List<Pago> listar() {
        return pagoRepository.listarConDatos();
    }

    public Pago buscarPorId(Integer id) {
        return pagoRepository.findById(id).orElse(null);
    }

    public Pago guardar(Pago pago) {
        return pagoRepository.save(pago);
    }

    public void eliminar(Integer id) {
        pagoRepository.deleteById(id);
    }
}
