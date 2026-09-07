package com.reyescompany.app.controller;

import com.reyescompany.app.model.Abono;
import com.reyescompany.app.service.AbonoService;
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
@RequestMapping("/api/abonos")
@CrossOrigin(origins = "*")
public class AbonoController {

    @Autowired
    private AbonoService abonoService;

    @GetMapping
    public List<Abono> listar() {
        return abonoService.listar();
    }

    @GetMapping("/{id}")
    public Abono buscarPorId(@PathVariable Integer id) {
        return abonoService.buscarPorId(id);
    }

    @PostMapping
    public Abono crear(@RequestBody Abono abono) {
        return abonoService.guardar(abono);
    }

    @PutMapping("/{id}")
    public Abono actualizar(@PathVariable Integer id, @RequestBody Abono abono) {
        abono.setIdAbono(id);
        return abonoService.guardar(abono);
    }

    @DeleteMapping("/{id}")
    public void eliminar(@PathVariable Integer id) {
        abonoService.eliminar(id);
    }
}
