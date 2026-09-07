package com.reyescompany.app.service;

import com.reyescompany.app.model.Usuario;
import com.reyescompany.app.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class UsuarioService {

    @Autowired
    private UsuarioRepository usuarioRepository;

    public List<Usuario> listar() {
        return usuarioRepository.findAll();
    }

    public Usuario buscarPorId(Integer id) {
        return usuarioRepository.findById(id).orElse(null);
    }

    public Usuario buscarPorEmail(String email) {
        return usuarioRepository.findByEmail(email);
    }

    public Usuario guardar(Usuario usuario) {
        if (usuario.getIdUsuario() != null) {
            Usuario existente = usuarioRepository.findById(usuario.getIdUsuario()).orElse(null);
            if (existente != null) {
                usuario.setCreatedAt(existente.getCreatedAt());
            }
        } else {
            usuario.setCreatedAt(LocalDateTime.now());
        }
        usuario.setUpdatedAt(LocalDateTime.now());
        return usuarioRepository.save(usuario);
    }

    public void eliminar(Integer id) {
        usuarioRepository.deleteById(id);
    }
}
