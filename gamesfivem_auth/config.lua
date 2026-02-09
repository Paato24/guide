-- Configuración del Sistema de Autenticación GamesFiveM
-- Este archivo puede usarse para futuras configuraciones

Config = {}

-- Configuración del Servidor
Config.ServerName = "GamesFiveM"
Config.ServerDescription = "El mejor servidor de minijuegos en FiveM"

-- Configuración de Seguridad
Config.MinPasswordLength = 6
Config.MinUsernameLength = 3
Config.MaxUsernameLength = 20

-- Configuración de Sesión
Config.SessionTimeout = 0 -- 0 = sin timeout, sesiones permanentes

-- Mensajes Personalizados
Config.Messages = {
    Welcome = "¡Bienvenido a GamesFiveM!",
    RegisterSuccess = "¡Cuenta creada exitosamente!",
    LoginSuccess = "¡Inicio de sesión exitoso!",
    AuthRequired = "Debes autenticarte primero en GamesFiveM",
    
    -- Errores
    AllFieldsRequired = "Todos los campos son obligatorios",
    InvalidEmail = "Formato de correo electrónico inválido",
    PasswordTooShort = "La contraseña debe tener al menos 6 caracteres",
    EmailExists = "Este correo electrónico ya está registrado",
    UsernameExists = "Este nombre de usuario ya está en uso",
    InvalidCredentials = "Correo o contraseña incorrectos",
    PasswordMismatch = "Las contraseñas no coinciden",
    UsernameInvalid = "El nombre de usuario solo puede contener letras, números y guiones bajos"
}

-- Debug Mode (solo para desarrollo)
Config.Debug = false

-- Webhook Discord (opcional)
Config.Webhook = {
    Enabled = false,
    URL = "",
    Color = 16744192, -- Naranja de GamesFiveM
    ShowRegistrations = true,
    ShowLogins = true
}

return Config
