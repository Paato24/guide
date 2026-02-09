/* ============================================
   GamesFiveM - Login System JavaScript
   NUI Handler for FiveM
   ============================================ */

let isAuthenticated = false;
let notifTimeout = null;

// ============================================
// Initialization
// ============================================

document.addEventListener('DOMContentLoaded', () => {
    createParticles();
    setupInputAnimations();
    setupKeyboardNav();
});

// Listen for NUI messages from client.lua
window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'open':
            openUI();
            break;

        case 'close':
            closeUI();
            break;

        case 'accountFound':
            // Player has account - show login with pre-filled email
            document.getElementById('loginEmail').value = data.email || '';
            showForm('login');
            showNotification('info', `Bienvenido de nuevo. Inicia sesión para continuar.`);
            break;

        case 'noAccount':
            // No account found - show register
            showForm('register');
            showNotification('info', '¡Bienvenido! Crea tu cuenta para comenzar a jugar.');
            break;

        case 'response':
            hideLoading();
            enableButtons();

            if (data.success) {
                showNotification('success', data.message);
                if (data.responseAction === 'registered' || data.responseAction === 'loggedin') {
                    isAuthenticated = true;
                    setTimeout(() => {
                        showPlayScreen(data.message);
                    }, 800);
                }
            } else {
                showNotification('error', data.message);
                // Shake the active form
                const activeForm = document.querySelector('.auth-form.active');
                if (activeForm) {
                    activeForm.classList.add('shake');
                    setTimeout(() => activeForm.classList.remove('shake'), 500);
                }
            }
            break;
    }
});

// ============================================
// UI Control Functions
// ============================================

function openUI() {
    const app = document.getElementById('app');
    app.classList.remove('hidden');
    // Reset state
    isAuthenticated = false;
    resetForms();
}

function closeUI() {
    const app = document.getElementById('app');
    app.style.opacity = '0';
    app.style.transform = 'scale(0.95)';
    app.style.transition = 'all 0.5s cubic-bezier(0.4, 0, 0.2, 1)';
    setTimeout(() => {
        app.classList.add('hidden');
        app.style.opacity = '';
        app.style.transform = '';
        app.style.transition = '';
    }, 500);
}

function showForm(formName) {
    // Hide all forms
    document.querySelectorAll('.auth-form').forEach(form => {
        form.classList.remove('active');
    });

    // Show target form
    const targetForm = document.getElementById(formName + 'Form');
    if (targetForm) {
        targetForm.classList.add('active');
        // Focus first input
        const firstInput = targetForm.querySelector('input');
        if (firstInput) {
            setTimeout(() => firstInput.focus(), 300);
        }
    }
}

function showPlayScreen(message) {
    document.querySelectorAll('.auth-form').forEach(form => {
        form.classList.remove('active');
    });

    const playScreen = document.getElementById('playScreen');
    playScreen.classList.add('active');

    // Update welcome text based on message
    const welcomeText = document.getElementById('welcomeText');
    const welcomeSubtext = document.getElementById('welcomeSubtext');

    if (message && message.includes('Bienvenido de nuevo')) {
        welcomeText.textContent = '¡Bienvenido de nuevo!';
        welcomeSubtext.textContent = 'Listo para la acción';
    } else {
        welcomeText.textContent = '¡Cuenta Creada!';
        welcomeSubtext.textContent = 'Tu aventura en GamesFiveM comienza ahora';
    }
}

function resetForms() {
    document.querySelectorAll('input').forEach(input => {
        input.value = '';
        input.classList.remove('input-error', 'input-success');
    });
    document.querySelectorAll('select').forEach(select => {
        select.selectedIndex = 0;
    });
    // Show login by default
    showForm('login');
}

// ============================================
// Auth Handlers
// ============================================

function handleLogin() {
    const email = document.getElementById('loginEmail').value.trim();
    const password = document.getElementById('loginPassword').value;

    // Clear previous errors
    clearInputErrors();

    // Validate
    let hasError = false;

    if (!email || !isValidEmail(email)) {
        setInputError('loginEmail');
        hasError = true;
    }

    if (!password) {
        setInputError('loginPassword');
        hasError = true;
    }

    if (hasError) {
        showNotification('error', 'Por favor, completa todos los campos correctamente.');
        return;
    }

    disableButtons();
    showLoading();

    // Send to FiveM client
    fetch(`https://${GetParentResourceName()}/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            email: email,
            password: password
        })
    }).catch(err => {
        console.error('Login error:', err);
        hideLoading();
        enableButtons();
    });
}

function handleRegister() {
    const email = document.getElementById('regEmail').value.trim();
    const username = document.getElementById('regUsername').value.trim();
    const password = document.getElementById('regPassword').value;
    const passwordConfirm = document.getElementById('regPasswordConfirm').value;
    const nationality = document.getElementById('regNationality').value;

    // Clear previous errors
    clearInputErrors();

    let hasError = false;
    let errorMessages = [];

    if (!email || !isValidEmail(email)) {
        setInputError('regEmail');
        errorMessages.push('Correo inválido');
        hasError = true;
    }

    if (!username || username.length < 3) {
        setInputError('regUsername');
        errorMessages.push('Usuario mín. 3 caracteres');
        hasError = true;
    }

    if (!password || password.length < 6) {
        setInputError('regPassword');
        errorMessages.push('Contraseña mín. 6 caracteres');
        hasError = true;
    }

    if (password !== passwordConfirm) {
        setInputError('regPasswordConfirm');
        errorMessages.push('Las contraseñas no coinciden');
        hasError = true;
    }

    if (!nationality) {
        setInputError('regNationality');
        errorMessages.push('Selecciona tu nacionalidad');
        hasError = true;
    }

    if (hasError) {
        showNotification('error', errorMessages.join('. ') + '.');
        return;
    }

    disableButtons();
    showLoading();

    // Send to FiveM client
    fetch(`https://${GetParentResourceName()}/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            email: email,
            username: username,
            password: password,
            nationality: nationality
        })
    }).catch(err => {
        console.error('Register error:', err);
        hideLoading();
        enableButtons();
    });
}

function handlePlay() {
    if (!isAuthenticated) {
        showNotification('error', 'Debes iniciar sesión primero.');
        return;
    }

    // Disable the play button to prevent double clicks
    const btnPlay = document.getElementById('btnPlay');
    btnPlay.disabled = true;
    btnPlay.style.pointerEvents = 'none';

    showLoading();

    fetch(`https://${GetParentResourceName()}/play`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).catch(err => {
        console.error('Play error:', err);
        hideLoading();
        btnPlay.disabled = false;
        btnPlay.style.pointerEvents = '';
    });
}

// ============================================
// Utility Functions
// ============================================

function isValidEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
}

function setInputError(inputId) {
    const input = document.getElementById(inputId);
    if (input) {
        input.classList.add('input-error');
        input.addEventListener('input', function handler() {
            input.classList.remove('input-error');
            input.removeEventListener('input', handler);
        }, { once: true });
    }
}

function clearInputErrors() {
    document.querySelectorAll('.input-error').forEach(el => {
        el.classList.remove('input-error');
    });
}

function togglePassword(inputId, toggleEl) {
    const input = document.getElementById(inputId);
    const icon = toggleEl.querySelector('i');

    if (input.type === 'password') {
        input.type = 'text';
        icon.classList.remove('fa-eye');
        icon.classList.add('fa-eye-slash');
    } else {
        input.type = 'password';
        icon.classList.remove('fa-eye-slash');
        icon.classList.add('fa-eye');
    }
}

function disableButtons() {
    document.querySelectorAll('.btn-primary').forEach(btn => {
        btn.disabled = true;
    });
}

function enableButtons() {
    document.querySelectorAll('.btn-primary').forEach(btn => {
        btn.disabled = false;
    });
}

// ============================================
// Notification System
// ============================================

function showNotification(type, message) {
    const notif = document.getElementById('notification');
    const notifIcon = document.getElementById('notifIcon');
    const notifMessage = document.getElementById('notifMessage');

    // Clear existing timeout
    if (notifTimeout) {
        clearTimeout(notifTimeout);
    }

    // Remove previous classes
    notif.classList.remove('hidden', 'success', 'error', 'info', 'hide-anim');

    // Set type
    notif.classList.add(type);

    // Set icon
    switch (type) {
        case 'success':
            notifIcon.className = 'fas fa-check-circle';
            break;
        case 'error':
            notifIcon.className = 'fas fa-exclamation-circle';
            break;
        case 'info':
            notifIcon.className = 'fas fa-info-circle';
            break;
    }

    // Set message
    notifMessage.textContent = message;

    // Auto-hide after 5 seconds
    notifTimeout = setTimeout(() => {
        hideNotification();
    }, 5000);
}

function hideNotification() {
    const notif = document.getElementById('notification');
    notif.classList.add('hide-anim');
    setTimeout(() => {
        notif.classList.add('hidden');
        notif.classList.remove('hide-anim', 'success', 'error', 'info');
    }, 400);
}

// ============================================
// Loading Overlay
// ============================================

function showLoading() {
    document.getElementById('loadingOverlay').classList.remove('hidden');
}

function hideLoading() {
    document.getElementById('loadingOverlay').classList.add('hidden');
}

// ============================================
// Particles System
// ============================================

function createParticles() {
    const container = document.getElementById('particles');
    const particleCount = 30;

    for (let i = 0; i < particleCount; i++) {
        const particle = document.createElement('div');
        particle.classList.add('particle');

        const x = Math.random() * 100;
        const size = Math.random() * 3 + 1;
        const duration = Math.random() * 15 + 10;
        const delay = Math.random() * 15;
        const opacity = Math.random() * 0.4 + 0.1;

        particle.style.left = x + '%';
        particle.style.width = size + 'px';
        particle.style.height = size + 'px';
        particle.style.animationDuration = duration + 's';
        particle.style.animationDelay = delay + 's';
        particle.style.maxOpacity = opacity;

        container.appendChild(particle);
    }
}

// ============================================
// Input Animations & Keyboard Navigation
// ============================================

function setupInputAnimations() {
    document.querySelectorAll('.input-group input').forEach(input => {
        input.addEventListener('focus', function () {
            this.parentElement.style.transform = 'scale(1.01)';
        });
        input.addEventListener('blur', function () {
            this.parentElement.style.transform = 'scale(1)';
        });
    });
}

function setupKeyboardNav() {
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
            e.preventDefault();

            // Check which form is active
            const loginForm = document.getElementById('loginForm');
            const registerForm = document.getElementById('registerForm');
            const playScreen = document.getElementById('playScreen');

            if (loginForm.classList.contains('active')) {
                handleLogin();
            } else if (registerForm.classList.contains('active')) {
                handleRegister();
            } else if (playScreen.classList.contains('active')) {
                handlePlay();
            }
        }

        // Tab navigation within forms
        if (e.key === 'Tab') {
            // Let default tab behavior work
        }
    });
}

// ============================================
// FiveM Resource Name Helper
// ============================================

function GetParentResourceName() {
    return window.GetParentResourceName ? window.GetParentResourceName() : 'gfm_login';
}
