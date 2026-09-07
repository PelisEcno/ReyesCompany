package com.reyescompany.app.controller;

import com.reyescompany.app.model.LoginRequest;
import com.reyescompany.app.model.Usuario;
import com.reyescompany.app.service.UsuarioService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @Autowired
    private UsuarioService usuarioService;

    @PostMapping("/login")
    public ResponseEntity<Usuario> login(@RequestBody LoginRequest loginRequest) {
        Usuario usuario = usuarioService.buscarPorEmail(loginRequest.getEmail());

        if (usuario == null) {
            return ResponseEntity.status(401).build();
        }

        boolean passwordCorrecta = usuarioService.verificarPassword(loginRequest.getPassword(), usuario.getPasswordHash());

        if (!passwordCorrecta) {
            return ResponseEntity.status(401).build();
        }

        if (!usuario.getActivo()) {
            return ResponseEntity.status(403).build();
        }

        usuario.setPasswordHash(null);
        return ResponseEntity.ok(usuario);
    }
}
