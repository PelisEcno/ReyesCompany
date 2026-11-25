package com.reyescompany.app.model;

import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Getter
@Setter
public class ItemVentaRequest {

    private Integer idInventario;
    private Integer cantidad;
    private BigDecimal precioUnitario;
}
