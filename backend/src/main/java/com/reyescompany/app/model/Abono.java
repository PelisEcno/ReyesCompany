package com.reyescompany.app.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "abono")
public class Abono {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_abono")
    private Integer idAbono;

    @Column(nullable = false)
    private BigDecimal monto;

    @Column(nullable = false)
    private LocalDate fecha;

    @ManyToOne
    @JoinColumn(name = "id_deuda_cliente", nullable = false)
    private DeudaCliente deudaCliente;

    public Integer getIdAbono() {
        return idAbono;
    }

    public void setIdAbono(Integer idAbono) {
        this.idAbono = idAbono;
    }

    public BigDecimal getMonto() {
        return monto;
    }

    public void setMonto(BigDecimal monto) {
        this.monto = monto;
    }

    public LocalDate getFecha() {
        return fecha;
    }

    public void setFecha(LocalDate fecha) {
        this.fecha = fecha;
    }

    public DeudaCliente getDeudaCliente() {
        return deudaCliente;
    }

    public void setDeudaCliente(DeudaCliente deudaCliente) {
        this.deudaCliente = deudaCliente;
    }
}
