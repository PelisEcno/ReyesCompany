package com.reyescompany.app.controller;

import com.reyescompany.app.model.Sucursal;
import com.reyescompany.app.service.SucursalService;
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
@RequestMapping("/api/sucursales")
@CrossOrigin(origins = "*")
public class SucursalController {

    @Autowired
    private SucursalService sucursalService;

    @GetMapping
    public List<Sucursal> listar() {
        return sucursalService.listar();
    }

    @GetMapping("/{id}")
    public Sucursal buscarPorId(@PathVariable Integer id) {
        return sucursalService.buscarPorId(id);
    }

    @PostMapping
    public Sucursal crear(@RequestBody Sucursal sucursal) {
        return sucursalService.guardar(sucursal);
    }

    @PutMapping("/{id}")
    public Sucursal actualizar(@PathVariable Integer id, @RequestBody Sucursal sucursal) {
        sucursal.setId(id);
        return sucursalService.guardar(sucursal);
    }

    @DeleteMapping("/{id}")
    public void eliminar(@PathVariable Integer id) {
        sucursalService.eliminar(id);
    }
}
