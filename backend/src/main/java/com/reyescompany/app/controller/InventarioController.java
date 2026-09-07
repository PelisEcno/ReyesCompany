package com.reyescompany.app.controller;

import com.reyescompany.app.model.Inventario;
import com.reyescompany.app.service.InventarioService;
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
@RequestMapping("/api/inventario")
@CrossOrigin(origins = "*")
public class InventarioController {

    @Autowired
    private InventarioService inventarioService;

    @GetMapping
    public List<Inventario> listar() {
        return inventarioService.listar();
    }

    @GetMapping("/{id}")
    public Inventario buscarPorId(@PathVariable Integer id) {
        return inventarioService.buscarPorId(id);
    }

    @PostMapping
    public Inventario crear(@RequestBody Inventario inventario) {
        return inventarioService.guardar(inventario);
    }

    @PutMapping("/{id}")
    public Inventario actualizar(@PathVariable Integer id, @RequestBody Inventario inventario) {
        inventario.setIdInventario(id);
        return inventarioService.guardar(inventario);
    }

    @DeleteMapping("/{id}")
    public void eliminar(@PathVariable Integer id) {
        inventarioService.eliminar(id);
    }
}
