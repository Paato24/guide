-- Tabla de usuarios registrados
CREATE TABLE IF NOT EXISTS `gamesfivem_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `username` varchar(50) NOT NULL,
  `nationality` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_login` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla para vincular cuentas con identifiers de FiveM
CREATE TABLE IF NOT EXISTS `gamesfivem_user_identifiers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `identifier` varchar(255) NOT NULL,
  `license` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `gamesfivem_user_identifiers_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `gamesfivem_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Índices para mejorar el rendimiento
CREATE INDEX idx_email ON gamesfivem_users(email);
CREATE INDEX idx_identifier ON gamesfivem_user_identifiers(identifier);
