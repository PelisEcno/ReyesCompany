INSERT INTO sucursal (id_sucursal, nombre, direccion, telefono, estado) VALUES
(100, 'Sucursal Principal', 'Calle 10 #5-20', '3001112233', 1),
(101, 'Sucursal Norte', 'Av Norte #45-10', '3002223344', 1);

INSERT INTO categoria (id_categoria, nombre) VALUES
(100, 'Bebidas'),
(101, 'Snacks'),
(102, 'Aseo');

INSERT INTO metodo_pago (id_metodo_pago, activo, nombre) VALUES
(100, 1, 'Efectivo'),
(101, 1, 'Tarjeta'),
(102, 1, 'Nequi');

INSERT INTO rol (id_rol, nombre) VALUES
(100, 'Administrador'),
(101, 'Empleado');

INSERT INTO permiso (id_permiso, nombre, descripcion) VALUES
(100, 'gestionar_usuarios', 'Crear, editar y desactivar usuarios'),
(101, 'gestionar_inventario', 'Crear y editar productos e inventario'),
(102, 'registrar_ventas', 'Registrar ventas y abonos'),
(103, 'ver_reportes', 'Ver resumenes e historial');

INSERT INTO rol_permiso (id_rol_permiso, id_rol, id_permiso) VALUES
(100, 100, 100),
(101, 100, 101),
(102, 100, 102),
(103, 100, 103),
(104, 101, 102),
(105, 101, 103);

-- password para los dos usuarios: 123456
INSERT INTO usuario (id_usuario, nombre, email, password_hash, activo, created_at, updated_at, fecha_nacimiento, fecha_vencimiento_clave, tratamiento_datos, id_rol) VALUES
(100, 'Carlos Reyes', 'carlos@reyescompany.com', '$2a$10$eCsGudiB51wmcy0eT1xsMuqke2fvAnsg0za5iELGA3fhhxEiKtu2a', 1, NOW(), NOW(), '1990-05-10 00:00:00', '2099-01-01 00:00:00', 1, 100),
(101, 'Laura Gomez', 'laura@reyescompany.com', '$2a$10$eCsGudiB51wmcy0eT1xsMuqke2fvAnsg0za5iELGA3fhhxEiKtu2a', 1, NOW(), NOW(), '1995-08-20 00:00:00', '2099-01-01 00:00:00', 1, 101);

INSERT INTO cliente (id_cliente, nombre, apellido, telefono, direccion, created_at, updated_at) VALUES
(100, 'Consumidor', 'Final', '', '', NOW(), NOW()),
(101, 'Pedro', 'Martinez', '3101112233', 'Calle 20 #10-5', NOW(), NOW()),
(102, 'Ana', 'Torres', '3202223344', 'Carrera 15 #8-30', NOW(), NOW());

INSERT INTO producto (id_producto, nombre, descripcion, precio_compra, precio_venta, created_at, updated_at, id_categoria) VALUES
(100, 'Coca Cola 400ml', 'Gaseosa personal', 3000, 4500, NOW(), NOW(), 100),
(101, 'Agua 600ml', 'Agua sin gas', 1500, 2500, NOW(), NOW(), 100),
(102, 'Papas Margarita', 'Paquete individual', 2000, 3500, NOW(), NOW(), 101),
(103, 'Jabon Rey', 'Barra 300g', 2500, 4000, NOW(), NOW(), 102),
(104, 'Chocolatina Jet', 'Unidad', 1000, 1800, NOW(), NOW(), 101);

INSERT INTO inventario (id_inventario, stock, stock_minimo, created_at, updated_at, id_producto, id_sucursal) VALUES
(100, 50, 10, NOW(), NOW(), 100, 100),
(101, 30, 5, NOW(), NOW(), 101, 100),
(102, 40, 8, NOW(), NOW(), 102, 100),
(103, 25, 5, NOW(), NOW(), 103, 100),
(104, 60, 10, NOW(), NOW(), 104, 100),
(105, 20, 5, NOW(), NOW(), 100, 101),
(106, 15, 5, NOW(), NOW(), 102, 101);

INSERT INTO venta (id_venta, fecha, total, created_at, updated_at, id_usuario, id_sucursal, id_cliente) VALUES
(100, CURDATE(), 9000, NOW(), NOW(), 100, 100, 100),
(101, CURDATE(), 4000, NOW(), NOW(), 100, 100, 101);

INSERT INTO detalle_venta (id_detalle_venta, cantidad, precio_unitario, id_inventario, id_venta) VALUES
(100, 2, 4500, 100, 100),
(101, 1, 4000, 103, 101);

-- venta 100 fue de contado
INSERT INTO pago (id_pago, monto, fecha, id_metodo_pago, id_venta) VALUES
(100, 9000, CURDATE(), 100, 100);

-- venta 101 fue fiada a Pedro Martinez
INSERT INTO deuda_cliente (id_deuda_cliente, fecha_deuda, updated_at, id_cliente, id_venta) VALUES
(100, NOW(), NOW(), 101, 101);

-- Pedro ya abono parte de esa deuda (1500 de 4000)
INSERT INTO abono (id_abono, monto, fecha, id_deuda_cliente) VALUES
(100, 1500, CURDATE(), 100);

INSERT INTO tipo_movimiento (id_tipo_movimiento, nombre) VALUES
(100, 'Entrada'),
(101, 'Salida'),
(102, 'Venta'),
(103, 'Ajuste');

INSERT INTO movimiento_inventario (id_movimiento_inventario, cantidad, fecha, id_tipo_movimiento, id_inventario, id_venta) VALUES
(100, 2, NOW(), 102, 100, 100),
(101, 1, NOW(), 102, 103, 101);
