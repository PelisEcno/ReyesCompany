package com.reyescompany.app.service;

import com.reyescompany.app.model.Usuario;
import com.reyescompany.app.repository.UsuarioRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class UsuarioServiceTest {

    @Mock
    private UsuarioRepository usuarioRepository;

    @InjectMocks
    private UsuarioService usuarioService;

    @Test
    public void guardarUsuarioNuevoCifraLaContrasena() {
        Usuario usuario = new Usuario();
        usuario.setNombre("Carlos Reyes");
        usuario.setPasswordHash("123456");
        when(usuarioRepository.save(any(Usuario.class))).thenAnswer(inv -> inv.getArgument(0));

        Usuario guardado = usuarioService.guardar(usuario);

        assertNotEquals("123456", guardado.getPasswordHash());
        assertTrue(guardado.getPasswordHash().startsWith("$2"));
    }

    @Test
    public void verificarPasswordAceptaLaCorrectaYRechazaLaIncorrecta() {
        Usuario usuario = new Usuario();
        usuario.setPasswordHash("123456");
        when(usuarioRepository.save(any(Usuario.class))).thenAnswer(inv -> inv.getArgument(0));
        Usuario guardado = usuarioService.guardar(usuario);

        assertTrue(usuarioService.verificarPassword("123456", guardado.getPasswordHash()));
        assertFalse(usuarioService.verificarPassword("otraClave", guardado.getPasswordHash()));
    }

    @Test
    public void editarUsuarioConservaLaContrasenaGuardada() {
        Usuario existente = new Usuario();
        existente.setIdUsuario(5);
        existente.setPasswordHash("hashGuardado");
        existente.setCreatedAt(LocalDateTime.now());
        when(usuarioRepository.findById(5)).thenReturn(Optional.of(existente));
        when(usuarioRepository.save(any(Usuario.class))).thenAnswer(inv -> inv.getArgument(0));

        Usuario cambios = new Usuario();
        cambios.setIdUsuario(5);
        cambios.setNombre("Nombre nuevo");

        Usuario guardado = usuarioService.guardar(cambios);

        assertEquals("hashGuardado", guardado.getPasswordHash());
        assertEquals("Nombre nuevo", guardado.getNombre());
    }

    @Test
    public void cambiarPasswordGuardaUnHashQueValidaConLaClaveNueva() {
        Usuario usuario = new Usuario();
        usuario.setIdUsuario(7);
        usuario.setPasswordHash("hashViejo");
        when(usuarioRepository.findById(7)).thenReturn(Optional.of(usuario));
        when(usuarioRepository.save(any(Usuario.class))).thenAnswer(inv -> inv.getArgument(0));

        Usuario resultado = usuarioService.cambiarPassword(7, "claveNueva");

        assertTrue(usuarioService.verificarPassword("claveNueva", resultado.getPasswordHash()));
    }

    @Test
    public void cambiarPasswordDeUsuarioInexistenteDevuelveNullYNoGuarda() {
        when(usuarioRepository.findById(99)).thenReturn(Optional.empty());

        Usuario resultado = usuarioService.cambiarPassword(99, "claveNueva");

        assertNull(resultado);
        verify(usuarioRepository, never()).save(any(Usuario.class));
    }
}
