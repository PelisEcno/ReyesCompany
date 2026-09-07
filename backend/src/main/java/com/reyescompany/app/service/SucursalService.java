package com.reyescompany.app.service;

import com.reyescompany.app.model.Sucursal;
import com.reyescompany.app.repository.SucursalRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class SucursalService {

    @Autowired
    private SucursalRepository sucursalRepository;

    public List<Sucursal> listar() {
        return sucursalRepository.findAll();
    }

    public Sucursal buscarPorId(Integer id) {
        return sucursalRepository.findById(id).orElse(null);
    }

    public Sucursal guardar(Sucursal sucursal) {
        return sucursalRepository.save(sucursal);
    }

    public void eliminar(Integer id) {
        sucursalRepository.deleteById(id);
    }
}
