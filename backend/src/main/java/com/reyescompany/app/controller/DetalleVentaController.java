package com.reyescompany.app.controller;

import com.reyescompany.app.model.DetalleVenta;
import com.reyescompany.app.service.DetalleVentaService;
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
@RequestMapping("/api/detalle-venta")
@CrossOrigin(origins = "*")
public class DetalleVentaController {

    @Autowired
    private DetalleVentaService detalleVentaService;

    @GetMapping
    public List<DetalleVenta> listar() {
        return detalleVentaService.listar();
    }

    @GetMapping("/{id}")
    public DetalleVenta buscarPorId(@PathVariable Integer id) {
        return detalleVentaService.buscarPorId(id);
    }

    @PostMapping
    public DetalleVenta crear(@RequestBody DetalleVenta detalleVenta) {
        return detalleVentaService.guardar(detalleVenta);
    }

    @PutMapping("/{id}")
    public DetalleVenta actualizar(@PathVariable Integer id, @RequestBody DetalleVenta detalleVenta) {
        detalleVenta.setIdDetalleVenta(id);
        return detalleVentaService.guardar(detalleVenta);
    }

    @DeleteMapping("/{id}")
    public void eliminar(@PathVariable Integer id) {
        detalleVentaService.eliminar(id);
    }
}
