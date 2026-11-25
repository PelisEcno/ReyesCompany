package com.reyescompany.app.model;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class VentaRequest {

    private Integer idUsuario;
    private Integer idSucursal;
    private Integer idCliente;
    private Integer idMetodoPago;
    private Boolean esFiado;
    private List<ItemVentaRequest> items;
}
