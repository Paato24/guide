CREATE TABLE IF NOT EXISTS `gf_accounts` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(80) NOT NULL,
  `email` VARCHAR(120) NOT NULL,
  `password_hash` CHAR(64) NOT NULL,
  `password_salt` CHAR(16) NOT NULL,
  `username` VARCHAR(32) NOT NULL,
  `nationality` VARCHAR(32) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_login` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_identifier` (`identifier`),
  UNIQUE KEY `uniq_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
