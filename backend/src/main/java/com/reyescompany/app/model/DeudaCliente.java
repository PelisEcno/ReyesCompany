package com.reyescompany.app.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

@Entity
@Table(name = "deuda_cliente")
public class DeudaCliente {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_deuda_cliente")
    private Integer idDeudaCliente;

    @Column(name = "fecha_deuda", nullable = false)
    private LocalDateTime fechaDeuda;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @ManyToOne
    @JoinColumn(name = "id_cliente", nullable = false)
    private Cliente cliente;

    @ManyToOne
    @JoinColumn(name = "id_venta", nullable = false)
    private Venta venta;

    public Integer getIdDeudaCliente() {
        return idDeudaCliente;
    }

    public void setIdDeudaCliente(Integer idDeudaCliente) {
        this.idDeudaCliente = idDeudaCliente;
    }

    public LocalDateTime getFechaDeuda() {
        return fechaDeuda;
    }

    public void setFechaDeuda(LocalDateTime fechaDeuda) {
        this.fechaDeuda = fechaDeuda;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public Cliente getCliente() {
        return cliente;
    }

    public void setCliente(Cliente cliente) {
        this.cliente = cliente;
    }

    public Venta getVenta() {
        return venta;
    }

    public void setVenta(Venta venta) {
        this.venta = venta;
    }
}
