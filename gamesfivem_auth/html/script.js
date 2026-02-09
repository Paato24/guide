// State Management
let currentForm = 'login';

// Listener para mensajes desde el cliente
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.type === 'openAuth') {
        document.getElementById('auth-container').classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    } else if (data.type === 'closeAuth') {
        document.getElementById('auth-container').classList.add('hidden');
        document.body.style.overflow = 'auto';
    }
});

// Función para cambiar entre formularios
function switchForm(formType) {
    event.preventDefault();
    
    const loginForm = document.getElementById('login-form');
    const registerForm = document.getElementById('register-form');
    
    if (formType === 'login') {
        registerForm.classList.remove('active');
        loginForm.classList.add('active');
        currentForm = 'login';
        clearMessages();
    } else if (formType === 'register') {
        loginForm.classList.remove('active');
        registerForm.classList.add('active');
        currentForm = 'register';
        clearMessages();
    }
}

// Función para mostrar/ocultar contraseña
function togglePassword(inputId) {
    const input = document.getElementById(inputId);
    const icon = event.target;
    
    if (input.type === 'password') {
        input.type = 'text';
        icon.textContent = '👁️‍🗨️';
    } else {
        input.type = 'password';
        icon.textContent = '👁️';
    }
}

// Función para mostrar mensajes
function showMessage(formType, type, message) {
    const messageElement = document.getElementById(`${formType}-message`);
    messageElement.textContent = message;
    messageElement.className = `message ${type}`;
    messageElement.classList.remove('hidden');
    
    // Auto ocultar después de 5 segundos si es error
    if (type === 'error') {
        setTimeout(() => {
            messageElement.classList.add('hidden');
        }, 5000);
    }
}

// Función para limpiar mensajes
function clearMessages() {
    const messages = document.querySelectorAll('.message');
    messages.forEach(msg => msg.classList.add('hidden'));
}

// Función para manejar loading en botones
function setButtonLoading(button, loading) {
    const btnText = button.querySelector('.btn-text');
    const btnLoader = button.querySelector('.btn-loader');
    
    if (loading) {
        btnText.classList.add('hidden');
        btnLoader.classList.remove('hidden');
        button.disabled = true;
    } else {
        btnText.classList.remove('hidden');
        btnLoader.classList.add('hidden');
        button.disabled = false;
    }
}

// Función para enviar datos al cliente
function sendToClient(action, data) {
    return new Promise((resolve) => {
        fetch(`https://${GetParentResourceName()}/${action}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        })
        .then(response => response.json())
        .then(data => resolve(data))
        .catch(error => {
            console.error('Error:', error);
            resolve({ success: false, message: 'Error de conexión' });
        });
    });
}

// Handler para el formulario de login
document.getElementById('loginForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const button = this.querySelector('.btn');
    const email = document.getElementById('login-email').value.trim();
    const password = document.getElementById('login-password').value;
    
    // Validación básica
    if (!email || !password) {
        showMessage('login', 'error', 'Por favor completa todos los campos');
        return;
    }
    
    // Validar formato de email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        showMessage('login', 'error', 'Formato de correo electrónico inválido');
        return;
    }
    
    clearMessages();
    setButtonLoading(button, true);
    
    // Enviar al servidor
    const response = await sendToClient('login', {
        email: email,
        password: password
    });
    
    setButtonLoading(button, false);
    
    if (response.success) {
        showMessage('login', 'success', `¡Bienvenido de vuelta, ${response.username}!`);
        // La UI se cerrará desde el cliente
    } else {
        showMessage('login', 'error', response.message || 'Error al iniciar sesión');
    }
});

// Handler para el formulario de registro
document.getElementById('registerForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const button = this.querySelector('.btn');
    const email = document.getElementById('register-email').value.trim();
    const username = document.getElementById('register-username').value.trim();
    const password = document.getElementById('register-password').value;
    const confirmPassword = document.getElementById('register-confirm-password').value;
    const nationality = document.getElementById('register-nationality').value;
    
    // Validación básica
    if (!email || !username || !password || !confirmPassword || !nationality) {
        showMessage('register', 'error', 'Por favor completa todos los campos');
        return;
    }
    
    // Validar formato de email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        showMessage('register', 'error', 'Formato de correo electrónico inválido');
        return;
    }
    
    // Validar nombre de usuario
    if (username.length < 3 || username.length > 20) {
        showMessage('register', 'error', 'El nombre de usuario debe tener entre 3 y 20 caracteres');
        return;
    }
    
    const usernameRegex = /^[a-zA-Z0-9_]+$/;
    if (!usernameRegex.test(username)) {
        showMessage('register', 'error', 'El nombre de usuario solo puede contener letras, números y guiones bajos');
        return;
    }
    
    // Validar contraseña
    if (password.length < 6) {
        showMessage('register', 'error', 'La contraseña debe tener al menos 6 caracteres');
        return;
    }
    
    // Verificar que las contraseñas coincidan
    if (password !== confirmPassword) {
        showMessage('register', 'error', 'Las contraseñas no coinciden');
        return;
    }
    
    clearMessages();
    setButtonLoading(button, true);
    
    // Enviar al servidor
    const response = await sendToClient('register', {
        email: email,
        username: username,
        password: password,
        nationality: nationality
    });
    
    setButtonLoading(button, false);
    
    if (response.success) {
        showMessage('register', 'success', `¡Cuenta creada exitosamente! Bienvenido, ${username}!`);
        // Limpiar formulario
        this.reset();
        // La UI se cerrará desde el cliente
    } else {
        showMessage('register', 'error', response.message || 'Error al crear la cuenta');
    }
});

// Función para obtener el nombre del recurso (para desarrollo)
function GetParentResourceName() {
    if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
        return 'gamesfivem_auth'; // Para pruebas locales
    }
    
    const url = new URL(window.location.href);
    const match = url.hostname.match(/^([^.]+)\./);
    return match ? match[1] : 'gamesfivem_auth';
}

// Efecto de partículas mejorado
function createParticle() {
    const particle = document.createElement('div');
    particle.style.position = 'absolute';
    particle.style.width = '2px';
    particle.style.height = '2px';
    particle.style.background = Math.random() > 0.5 ? '#ff6b00' : '#ffd700';
    particle.style.borderRadius = '50%';
    particle.style.left = Math.random() * 100 + '%';
    particle.style.top = Math.random() * 100 + '%';
    particle.style.opacity = Math.random();
    particle.style.pointerEvents = 'none';
    particle.style.animation = `particleFade ${Math.random() * 3 + 2}s ease-in-out infinite`;
    
    document.querySelector('.particles').appendChild(particle);
    
    setTimeout(() => {
        particle.remove();
    }, 5000);
}

// Crear partículas continuamente
setInterval(createParticle, 200);

// Añadir animación CSS para las partículas
const style = document.createElement('style');
style.textContent = `
    @keyframes particleFade {
        0%, 100% { opacity: 0; transform: scale(0); }
        50% { opacity: 1; transform: scale(1); }
    }
`;
document.head.appendChild(style);

// Animación de entrada al cargar
window.addEventListener('load', function() {
    document.body.style.opacity = '0';
    setTimeout(() => {
        document.body.style.transition = 'opacity 0.5s';
        document.body.style.opacity = '1';
    }, 100);
});

// Prevenir clic derecho y F12 en producción
if (window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1') {
    document.addEventListener('contextmenu', e => e.preventDefault());
    document.addEventListener('keydown', e => {
        if (e.key === 'F12' || (e.ctrlKey && e.shiftKey && e.key === 'I')) {
            e.preventDefault();
        }
    });
}

// ESC para cerrar (solo si está autenticado, el cliente lo manejará)
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        sendToClient('closeUI', {});
    }
});

console.log('%c🎮 GamesFiveM Auth System', 'color: #ff6b00; font-size: 24px; font-weight: bold;');
console.log('%cSistema de autenticación v1.0', 'color: #ffd700; font-size: 14px;');
console.log('%c¡Bienvenido al mejor servidor de minijuegos!', 'color: #ffffff; font-size: 12px;');
