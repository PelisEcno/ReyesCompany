package com.reyescompany.app.service;

import com.reyescompany.app.model.DeudaCliente;
import com.reyescompany.app.repository.DeudaClienteRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class DeudaClienteService {

    @Autowired
    private DeudaClienteRepository deudaClienteRepository;

    public List<DeudaCliente> listar() {
        return deudaClienteRepository.findAll();
    }

    public DeudaCliente buscarPorId(Integer id) {
        return deudaClienteRepository.findById(id).orElse(null);
    }

    public DeudaCliente guardar(DeudaCliente deudaCliente) {
        if (deudaCliente.getIdDeudaCliente() != null) {
            DeudaCliente existente = deudaClienteRepository.findById(deudaCliente.getIdDeudaCliente()).orElse(null);
            if (existente != null) {
                deudaCliente.setFechaDeuda(existente.getFechaDeuda());
            }
        } else {
            deudaCliente.setFechaDeuda(LocalDateTime.now());
        }
        deudaCliente.setUpdatedAt(LocalDateTime.now());
        return deudaClienteRepository.save(deudaCliente);
    }

    public void eliminar(Integer id) {
        deudaClienteRepository.deleteById(id);
    }
}
