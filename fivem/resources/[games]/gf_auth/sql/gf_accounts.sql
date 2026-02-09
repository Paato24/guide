CREATE TABLE IF NOT EXISTS `gf_accounts` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `license` VARCHAR(64) NOT NULL,
  `email` VARCHAR(128) NOT NULL,
  `salt` CHAR(32) NOT NULL,
  `password_hash` CHAR(64) NOT NULL,
  `username` VARCHAR(24) NOT NULL,
  `nationality` VARCHAR(48) NOT NULL,
  `created_at` DATETIME NOT NULL,
  `last_login` DATETIME NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_email` (`email`),
  UNIQUE KEY `uniq_license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

