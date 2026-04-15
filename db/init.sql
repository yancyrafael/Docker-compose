CREATE DATABASE IF NOT EXISTS coffeeshop;
USE coffeeshop;

CREATE TABLE reservations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    date DATE NOT NULL,
    time TIME NOT NULL,
    guests INT NOT NULL,
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO reservations (name, email, phone, date, time, guests, message) VALUES
('Juan Pérez', 'juan@email.com', '514-555-0001', '2026-04-20', '14:00', 4, 'Mesa cerca de la ventana'),
('María López', 'maria@email.com', '514-555-0002', '2026-04-21', '19:00', 2, 'Aniversario');