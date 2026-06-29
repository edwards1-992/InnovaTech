/**
 * ================================================================
 *  INNOVATECH — script.js
 *  Lógica del formulario de Login y Registro (página login.html).
 *  Maneja el flip panel (inicio de sesión / creación de cuenta)
 *  y la comunicación con api/auth.php.
 *
 *  La clase CSS clave es "right-panel-active" (NO "show-register"),
 *  debe coincidir exactamente con lo que usa login.css.
 * ================================================================
 *
 * Flujo:
 *   1. Botones del overlay y enlaces mobile alternan la clase
 *      right-panel-active en el contenedor principal
 *   2. El formulario de registro envía POST a auth.php?action=registro
 *   3. El formulario de login envía POST a auth.php?action=login
 *   4. Tras login exitoso, guarda el usuario en localStorage y
 *      redirige a la página que el usuario intentaba visitar
 *      (redirectAfterLogin) o al home si no había redirect.
 */

// ═════════════════════════════════════════════════════════════
//  FLIP PANEL — Toggle entre login y registro
// ═════════════════════════════════════════════════════════════

// ─── Referencias DOM ─────────────────────────────────────────
const signUpButton = document.getElementById('signUp');
const signInButton = document.getElementById('signIn');
const container    = document.getElementById('container');

// Botones del overlay (panel decorativo)
signUpButton.addEventListener('click', () => {
  container.classList.add("right-panel-active");
});
signInButton.addEventListener('click', () => {
  container.classList.remove("right-panel-active");
});

// Enlaces en versión mobile (aparecen cuando el overlay se oculta)
document.getElementById('mobileGoRegister').addEventListener('click', (e) => {
  e.preventDefault();
  container.classList.add("right-panel-active");
});
document.getElementById('mobileGoLogin').addEventListener('click', (e) => {
  e.preventDefault();
  container.classList.remove("right-panel-active");
});

// ═════════════════════════════════════════════════════════════
//  TOAST — Notificación (independiente de app.js)
// ═════════════════════════════════════════════════════════════

function showToast(msg, tipo) {
  const c     = document.getElementById('toastContainer');
  const toast = document.createElement('div');
  toast.className = 'toast toast-' + (tipo === 'err' ? 'err' : 'ok');
  toast.innerHTML = '<i class="fas ' + (tipo === 'err' ? 'fa-times-circle' : 'fa-check-circle') + '"></i> ' + msg;
  c.appendChild(toast);
  setTimeout(function() {
    toast.classList.add('hide');
    setTimeout(function() { toast.remove(); }, 400);
  }, 3500);
}

// ═════════════════════════════════════════════════════════════
//  LOADING — Indicador de carga en botones
// ═════════════════════════════════════════════════════════════

// Muestra/oculta el spinner dentro del botón y lo deshabilita.
function setLoading(btn, loading) {
  btn.querySelector('.btn-txt').style.display  = loading ? 'none'   : '';
  btn.querySelector('.btn-load').style.display = loading ? 'inline' : 'none';
  btn.disabled = loading;
}

// ═════════════════════════════════════════════════════════════
//  FORMULARIO DE REGISTRO
// ═════════════════════════════════════════════════════════════

document.getElementById('formRegistro').addEventListener('submit', async function(e) {
  e.preventDefault();

  var nombre   = document.getElementById('regNombre').value.trim();
  var email    = document.getElementById('regEmail').value.trim();
  var password = document.getElementById('regPassword').value;
  var btn      = document.getElementById('btnReg');

  // Validaciones del lado del cliente
  if (!nombre) { showToast('El nombre es obligatorio', 'err'); return; }
  if (!email || email.indexOf('@') === -1) { showToast('Ingresa un correo válido', 'err'); return; }
  if (password.length < 6) { showToast('La contraseña debe tener al menos 6 caracteres', 'err'); return; }

  setLoading(btn, true);

  try {
    var res  = await fetch('api/auth.php?action=registro', {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ nombre, email, password })
    });
    var data = await res.json();

    if (data.ok) {
      showToast('Cuenta creada. Ahora inicia sesión.', 'ok');
      document.getElementById('formRegistro').reset();
      // Volver al panel de login tras 1.2s
      setTimeout(function() { container.classList.remove('right-panel-active'); }, 1200);
    } else {
      showToast(data.error || 'Error al registrar', 'err');
    }
  } catch (err) {
    showToast('Error de conexión. ¿XAMPP está corriendo?', 'err');
    console.error('registro:', err);
  }

  setLoading(btn, false);
});

// ═════════════════════════════════════════════════════════════
//  FORMULARIO DE LOGIN
// ═════════════════════════════════════════════════════════════

document.getElementById('formLogin').addEventListener('submit', async function(e) {
  e.preventDefault();

  var email    = document.getElementById('loginEmail').value.trim();
  var password = document.getElementById('loginPassword').value;
  var btn      = document.getElementById('btnLogin');

  if (!email || !password) { showToast('Ingresa tu correo y contraseña', 'err'); return; }

  setLoading(btn, true);

  try {
    var res  = await fetch('api/auth.php?action=login', {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });
    var data = await res.json();

    if (data.ok) {
      // Guardar sesión en localStorage con datos del usuario
      localStorage.setItem('it_user', JSON.stringify({
        id:     data.usuario.id,
        nombre: data.usuario.nombre,
        email:  data.usuario.email,
        rol:    data.usuario.rol,
      }));

      showToast('¡Bienvenido, ' + data.usuario.nombre + '!', 'ok');

      // Redirigir a la página donde el usuario intentaba comprar,
      // o al home si no había redirect pendiente
      setTimeout(function() {
        var redirect = localStorage.getItem('redirectAfterLogin');
        if (redirect && !redirect.includes('login.html')) {
          localStorage.removeItem('redirectAfterLogin');
          location.href = redirect;
        } else {
          location.href = 'index.html';
        }
      }, 1000);
    } else {
      showToast(data.error || 'Correo o contraseña incorrectos', 'err');
    }
  } catch (err) {
    showToast('Error de conexión. ¿XAMPP está corriendo?', 'err');
    console.error('login:', err);
  }

  setLoading(btn, false);
});
