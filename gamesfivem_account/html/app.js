const app = document.getElementById('app');
const tabs = document.querySelectorAll('.tab');
const panels = {
  login: document.getElementById('panel-login'),
  register: document.getElementById('panel-register'),
  play: document.getElementById('panel-play'),
};
const messageBox = document.getElementById('message');
const loginForm = document.getElementById('login-form');
const registerForm = document.getElementById('register-form');
const playButton = document.getElementById('play-button');
const accountEmail = document.getElementById('account-email');
const accountUsername = document.getElementById('account-username');

const resourceName =
  typeof GetParentResourceName === 'function'
    ? GetParentResourceName()
    : 'gamesfivem_account';

let authenticated = false;

const post = async (endpoint, data) => {
  const response = await fetch(`https://${resourceName}/${endpoint}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify(data || {}),
  });
  return response.json();
};

const setLoading = (element, isLoading) => {
  element.classList.toggle('loading', isLoading);
  const button = element.querySelector('button');
  if (button) {
    button.disabled = isLoading;
  }
};

const showMessage = (type, text) => {
  if (!text) {
    messageBox.classList.add('hidden');
    return;
  }

  messageBox.textContent = text;
  messageBox.classList.remove('hidden', 'success', 'error');
  messageBox.classList.add(type);
};

const showTab = (tabName) => {
  if (authenticated) {
    tabName = 'play';
  }

  Object.keys(panels).forEach((key) => {
    panels[key].classList.toggle('active', key === tabName);
  });

  tabs.forEach((tab) => {
    tab.classList.toggle('active', tab.dataset.tab === tabName);
  });
};

tabs.forEach((tab) => {
  tab.addEventListener('click', () => {
    if (authenticated) {
      return;
    }
    showTab(tab.dataset.tab);
    showMessage('', '');
  });
});

loginForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  setLoading(loginForm, true);
  showMessage('', '');

  const data = Object.fromEntries(new FormData(loginForm).entries());
  try {
    const result = await post('login', data);
    showMessage(result.ok ? 'success' : 'error', result.message);
  } catch (error) {
    showMessage('error', 'Error de conexion. Intenta de nuevo.');
  } finally {
    setLoading(loginForm, false);
  }
});

registerForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  setLoading(registerForm, true);
  showMessage('', '');

  const data = Object.fromEntries(new FormData(registerForm).entries());
  try {
    const result = await post('register', data);
    showMessage(result.ok ? 'success' : 'error', result.message);
  } catch (error) {
    showMessage('error', 'Error de conexion. Intenta de nuevo.');
  } finally {
    setLoading(registerForm, false);
  }
});

playButton.addEventListener('click', async () => {
  setLoading(panels.play, true);
  showMessage('', '');
  try {
    const result = await post('play', {});
    showMessage(result.ok ? 'success' : 'error', result.message);
  } catch (error) {
    showMessage('error', 'Error de conexion. Intenta de nuevo.');
  } finally {
    setLoading(panels.play, false);
  }
});

window.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.action === 'show') {
    app.classList.remove('hidden');
    showTab('login');
  }

  if (data.action === 'hide') {
    app.classList.add('hidden');
  }

  if (data.action === 'setAuthenticated') {
    authenticated = true;
    showTab('play');
    if (data.account) {
      accountEmail.textContent = data.account.email || '-';
      accountUsername.textContent = data.account.username || '-';
    }
  }
});

post('uiReady', {}).catch(() => {});
