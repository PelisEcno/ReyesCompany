package com.reyescompany.app.service;

import com.reyescompany.app.model.Permiso;
import com.reyescompany.app.repository.PermisoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PermisoService {

    @Autowired
    private PermisoRepository permisoRepository;

    public List<Permiso> listar() {
        return permisoRepository.findAll();
    }

    public Permiso buscarPorId(Integer id) {
        return permisoRepository.findById(id).orElse(null);
    }

    public Permiso guardar(Permiso permiso) {
        return permisoRepository.save(permiso);
    }

    public void eliminar(Integer id) {
        permisoRepository.deleteById(id);
    }
}
