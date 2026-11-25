package com.reyescompany.app.model;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class MovimientoRequest {

    private Integer idInventario;
    private String tipo;
    private Integer cantidad;
    private String observacion;
    private Integer idUsuario;
}
