package com.reyescompany.app.service;

import com.reyescompany.app.model.RolPermiso;
import com.reyescompany.app.repository.RolPermisoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class RolPermisoService {

    @Autowired
    private RolPermisoRepository rolPermisoRepository;

    public List<RolPermiso> listar() {
        return rolPermisoRepository.findAll();
    }

    public RolPermiso buscarPorId(Integer id) {
        return rolPermisoRepository.findById(id).orElse(null);
    }

    public RolPermiso guardar(RolPermiso rolPermiso) {
        return rolPermisoRepository.save(rolPermiso);
    }

    public void eliminar(Integer id) {
        rolPermisoRepository.deleteById(id);
    }
}
