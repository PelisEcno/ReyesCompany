package com.reyescompany.app.service;

import com.reyescompany.app.model.Abono;
import com.reyescompany.app.repository.AbonoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AbonoService {

    @Autowired
    private AbonoRepository abonoRepository;

    public List<Abono> listar() {
        return abonoRepository.listarConDatos();
    }

    public Abono buscarPorId(Integer id) {
        return abonoRepository.findById(id).orElse(null);
    }

    public Abono guardar(Abono abono) {
        return abonoRepository.save(abono);
    }

    public void eliminar(Integer id) {
        abonoRepository.deleteById(id);
    }
}
