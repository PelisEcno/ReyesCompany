package com.reyescompany.app.model;

import java.util.List;

public class VentaRequest {

    private Integer idUsuario;
    private Integer idSucursal;
    private Integer idCliente;
    private Integer idMetodoPago;
    private Boolean esFiado;
    private List<ItemVentaRequest> items;

    public Integer getIdUsuario() {
        return idUsuario;
    }

    public void setIdUsuario(Integer idUsuario) {
        this.idUsuario = idUsuario;
    }

    public Integer getIdSucursal() {
        return idSucursal;
    }

    public void setIdSucursal(Integer idSucursal) {
        this.idSucursal = idSucursal;
    }

    public Integer getIdCliente() {
        return idCliente;
    }

    public void setIdCliente(Integer idCliente) {
        this.idCliente = idCliente;
    }

    public Integer getIdMetodoPago() {
        return idMetodoPago;
    }

    public void setIdMetodoPago(Integer idMetodoPago) {
        this.idMetodoPago = idMetodoPago;
    }

    public Boolean getEsFiado() {
        return esFiado;
    }

    public void setEsFiado(Boolean esFiado) {
        this.esFiado = esFiado;
    }

    public List<ItemVentaRequest> getItems() {
        return items;
    }

    public void setItems(List<ItemVentaRequest> items) {
        this.items = items;
    }
}
