package com.reyescompany.app.controller;

import com.reyescompany.app.model.MetodoPago;
import com.reyescompany.app.service.MetodoPagoService;
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
@RequestMapping("/api/metodos-pago")
@CrossOrigin(origins = "*")
public class MetodoPagoController {

    @Autowired
    private MetodoPagoService metodoPagoService;

    @GetMapping
    public List<MetodoPago> listar() {
        return metodoPagoService.listar();
    }

    @GetMapping("/{id}")
    public MetodoPago buscarPorId(@PathVariable Integer id) {
        return metodoPagoService.buscarPorId(id);
    }

    @PostMapping
    public MetodoPago crear(@RequestBody MetodoPago metodoPago) {
        return metodoPagoService.guardar(metodoPago);
    }

    @PutMapping("/{id}")
    public MetodoPago actualizar(@PathVariable Integer id, @RequestBody MetodoPago metodoPago) {
        metodoPago.setId(id);
        return metodoPagoService.guardar(metodoPago);
    }

    @DeleteMapping("/{id}")
    public void eliminar(@PathVariable Integer id) {
        metodoPagoService.eliminar(id);
    }
}
