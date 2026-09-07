package com.reyescompany.app.controller;

import com.reyescompany.app.model.TipoMovimiento;
import com.reyescompany.app.service.TipoMovimientoService;
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
@RequestMapping("/api/tipos-movimiento")
@CrossOrigin(origins = "*")
public class TipoMovimientoController {

    @Autowired
    private TipoMovimientoService tipoMovimientoService;

    @GetMapping
    public List<TipoMovimiento> listar() {
        return tipoMovimientoService.listar();
    }

    @GetMapping("/{id}")
    public TipoMovimiento buscarPorId(@PathVariable Integer id) {
        return tipoMovimientoService.buscarPorId(id);
    }

    @PostMapping
    public TipoMovimiento crear(@RequestBody TipoMovimiento tipoMovimiento) {
        return tipoMovimientoService.guardar(tipoMovimiento);
    }

    @PutMapping("/{id}")
    public TipoMovimiento actualizar(@PathVariable Integer id, @RequestBody TipoMovimiento tipoMovimiento) {
        tipoMovimiento.setIdTipoMovimiento(id);
        return tipoMovimientoService.guardar(tipoMovimiento);
    }

    @DeleteMapping("/{id}")
    public void eliminar(@PathVariable Integer id) {
        tipoMovimientoService.eliminar(id);
    }
}
