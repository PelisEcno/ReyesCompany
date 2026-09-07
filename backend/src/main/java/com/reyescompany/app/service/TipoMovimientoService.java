package com.reyescompany.app.service;

import com.reyescompany.app.model.TipoMovimiento;
import com.reyescompany.app.repository.TipoMovimientoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class TipoMovimientoService {

    @Autowired
    private TipoMovimientoRepository tipoMovimientoRepository;

    public List<TipoMovimiento> listar() {
        return tipoMovimientoRepository.findAll();
    }

    public TipoMovimiento buscarPorId(Integer id) {
        return tipoMovimientoRepository.findById(id).orElse(null);
    }

    public TipoMovimiento guardar(TipoMovimiento tipoMovimiento) {
        return tipoMovimientoRepository.save(tipoMovimiento);
    }

    public void eliminar(Integer id) {
        tipoMovimientoRepository.deleteById(id);
    }
}
