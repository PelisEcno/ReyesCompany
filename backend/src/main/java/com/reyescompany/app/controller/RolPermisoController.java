package com.reyescompany.app.controller;

import com.reyescompany.app.model.RolPermiso;
import com.reyescompany.app.service.RolPermisoService;
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
@RequestMapping("/api/roles-permisos")
@CrossOrigin(origins = "*")
public class RolPermisoController {

    @Autowired
    private RolPermisoService rolPermisoService;

    @GetMapping
    public List<RolPermiso> listar() {
        return rolPermisoService.listar();
    }

    @GetMapping("/{id}")
    public RolPermiso buscarPorId(@PathVariable Integer id) {
        return rolPermisoService.buscarPorId(id);
    }

    @PostMapping
    public RolPermiso crear(@RequestBody RolPermiso rolPermiso) {
        return rolPermisoService.guardar(rolPermiso);
    }

    @PutMapping("/{id}")
    public RolPermiso actualizar(@PathVariable Integer id, @RequestBody RolPermiso rolPermiso) {
        rolPermiso.setIdRolPermiso(id);
        return rolPermisoService.guardar(rolPermiso);
    }

    @DeleteMapping("/{id}")
    public void eliminar(@PathVariable Integer id) {
        rolPermisoService.eliminar(id);
    }
}
