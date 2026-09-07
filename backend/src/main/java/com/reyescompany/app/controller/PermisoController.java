package com.reyescompany.app.controller;

import com.reyescompany.app.model.Permiso;
import com.reyescompany.app.service.PermisoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/permisos")
@CrossOrigin(origins = "*")
public class PermisoController {

    @Autowired
    private PermisoService permisoService;

    @GetMapping
    public List<Permiso> listar() {
        return permisoService.listar();
    }

    @GetMapping("/{id}")
    public Permiso buscarPorId(@PathVariable Integer id) {
        return permisoService.buscarPorId(id);
    }

    @PostMapping
    public Permiso crear(@RequestBody Permiso permiso) {
        return permisoService.guardar(permiso);
    }

    @PutMapping("/{id}")
    public Permiso actualizar(@PathVariable Integer id, @RequestBody Permiso permiso) {
        permiso.setIdPermiso(id);
        return permisoService.guardar(permiso);
    }

    @DeleteMapping("/{id}")
    public void eliminar(@PathVariable Integer id) {
        permisoService.eliminar(id);
    }
}
