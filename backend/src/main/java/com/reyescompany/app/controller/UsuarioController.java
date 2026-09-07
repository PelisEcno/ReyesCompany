package com.reyescompany.app.controller;

import com.reyescompany.app.model.CambiarPasswordRequest;
import com.reyescompany.app.model.Usuario;
import com.reyescompany.app.service.UsuarioService;
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
@RequestMapping("/api/usuarios")
@CrossOrigin(origins = "*")
public class UsuarioController {

    @Autowired
    private UsuarioService usuarioService;

    @GetMapping
    public List<Usuario> listar() {
        List<Usuario> usuarios = usuarioService.listar();
        for (Usuario usuario : usuarios) {
            usuario.setPasswordHash(null);
        }
        return usuarios;
    }

    @GetMapping("/{id}")
    public Usuario buscarPorId(@PathVariable Integer id) {
        Usuario usuario = usuarioService.buscarPorId(id);
        if (usuario != null) {
            usuario.setPasswordHash(null);
        }
        return usuario;
    }

    @PostMapping
    public Usuario crear(@RequestBody Usuario usuario) {
        Usuario creado = usuarioService.guardar(usuario);
        creado.setPasswordHash(null);
        return creado;
    }

    @PutMapping("/{id}")
    public Usuario actualizar(@PathVariable Integer id, @RequestBody Usuario usuario) {
        usuario.setIdUsuario(id);
        Usuario actualizado = usuarioService.guardar(usuario);
        actualizado.setPasswordHash(null);
        return actualizado;
    }

    @PutMapping("/{id}/password")
    public Usuario cambiarPassword(@PathVariable Integer id, @RequestBody CambiarPasswordRequest request) {
        Usuario actualizado = usuarioService.cambiarPassword(id, request.getPassword());
        if (actualizado != null) {
            actualizado.setPasswordHash(null);
        }
        return actualizado;
    }

    @DeleteMapping("/{id}")
    public void eliminar(@PathVariable Integer id) {
        usuarioService.eliminar(id);
    }
}
