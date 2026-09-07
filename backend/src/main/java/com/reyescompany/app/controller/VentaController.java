package com.reyescompany.app.controller;

import com.reyescompany.app.model.Venta;
import com.reyescompany.app.service.VentaService;
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
@RequestMapping("/api/ventas")
@CrossOrigin(origins = "*")
public class VentaController {

    @Autowired
    private VentaService ventaService;

    @GetMapping
    public List<Venta> listar() {
        return ventaService.listar();
    }

    @GetMapping("/{id}")
    public Venta buscarPorId(@PathVariable Integer id) {
        return ventaService.buscarPorId(id);
    }

    @PostMapping
    public Venta crear(@RequestBody Venta venta) {
        return ventaService.guardar(venta);
    }

    @PutMapping("/{id}")
    public Venta actualizar(@PathVariable Integer id, @RequestBody Venta venta) {
        venta.setIdVenta(id);
        return ventaService.guardar(venta);
    }

    @DeleteMapping("/{id}")
    public void eliminar(@PathVariable Integer id) {
        ventaService.eliminar(id);
    }
}
