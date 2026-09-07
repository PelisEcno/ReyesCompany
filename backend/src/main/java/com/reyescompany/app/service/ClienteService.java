package com.reyescompany.app.service;

import com.reyescompany.app.model.Cliente;
import com.reyescompany.app.repository.ClienteRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class ClienteService {

    @Autowired
    private ClienteRepository clienteRepository;

    public List<Cliente> listar() {
        return clienteRepository.findAll();
    }

    public Cliente buscarPorId(Integer id) {
        return clienteRepository.findById(id).orElse(null);
    }

    public Cliente guardar(Cliente cliente) {
        if (cliente.getIdCliente() != null) {
            Cliente existente = clienteRepository.findById(cliente.getIdCliente()).orElse(null);
            if (existente != null) {
                cliente.setCreatedAt(existente.getCreatedAt());
            }
        } else {
            cliente.setCreatedAt(LocalDateTime.now());
        }
        cliente.setUpdatedAt(LocalDateTime.now());
        return clienteRepository.save(cliente);
    }

    public void eliminar(Integer id) {
        clienteRepository.deleteById(id);
    }
}
