package com.reyescompany.app.controller;

import com.reyescompany.app.model.DeudaCliente;
import com.reyescompany.app.service.DeudaClienteService;
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
@RequestMapping("/api/deudas-cliente")
@CrossOrigin(origins = "*")
public class DeudaClienteController {

    @Autowired
    private DeudaClienteService deudaClienteService;

    @GetMapping
    public List<DeudaCliente> listar() {
        return deudaClienteService.listar();
    }

    @GetMapping("/{id}")
    public DeudaCliente buscarPorId(@PathVariable Integer id) {
        return deudaClienteService.buscarPorId(id);
    }

    @PostMapping
    public DeudaCliente crear(@RequestBody DeudaCliente deudaCliente) {
        return deudaClienteService.guardar(deudaCliente);
    }

    @PutMapping("/{id}")
    public DeudaCliente actualizar(@PathVariable Integer id, @RequestBody DeudaCliente deudaCliente) {
        deudaCliente.setIdDeudaCliente(id);
        return deudaClienteService.guardar(deudaCliente);
    }

    @DeleteMapping("/{id}")
    public void eliminar(@PathVariable Integer id) {
        deudaClienteService.eliminar(id);
    }
}
