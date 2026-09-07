package com.reyescompany.app.controller;

import com.reyescompany.app.model.MovimientoInventario;
import com.reyescompany.app.service.MovimientoInventarioService;
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
@RequestMapping("/api/movimientos-inventario")
@CrossOrigin(origins = "*")
public class MovimientoInventarioController {

    @Autowired
    private MovimientoInventarioService movimientoInventarioService;

    @GetMapping
    public List<MovimientoInventario> listar() {
        return movimientoInventarioService.listar();
    }

    @GetMapping("/{id}")
    public MovimientoInventario buscarPorId(@PathVariable Integer id) {
        return movimientoInventarioService.buscarPorId(id);
    }

    @PostMapping
    public MovimientoInventario crear(@RequestBody MovimientoInventario movimientoInventario) {
        return movimientoInventarioService.guardar(movimientoInventario);
    }

    @PutMapping("/{id}")
    public MovimientoInventario actualizar(@PathVariable Integer id, @RequestBody MovimientoInventario movimientoInventario) {
        movimientoInventario.setIdMovimientoInventario(id);
        return movimientoInventarioService.guardar(movimientoInventario);
    }

    @DeleteMapping("/{id}")
    public void eliminar(@PathVariable Integer id) {
        movimientoInventarioService.eliminar(id);
    }
}
