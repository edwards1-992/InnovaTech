/**
 * ================================================================
 *  INNOVATECH — app.js
 *  Lógica compartida del frontend: carga de productos, carrito de
 *  compras, filtros del catálogo, checkout, contacto, toasts y
 *  gestión de sesión de usuario (visitante / cliente / admin).
 *
 *  Roles:
 *    - Visitante: navega sin login, pero NO puede agregar al
 *      carrito ni comprar (redirigido a login)
 *    - Cliente: compra con normalidad
 *    - Admin: mismo que cliente + enlace al panel admin.html
 *
 *  Persistencia:
 *    - Carrito: localStorage (clave 'innovatech_cart')
 *    - Sesión:  localStorage (clave 'it_user')
 * ================================================================
 */

// ─── Catálogo en memoria ─────────────────────────────────────
// Se llena cuando se llama a loadProducts() desde cada página.
let PRODUCTS = [];

// ─── Categorías (definidas en frontend) ──────────────────────
// Coinciden con las categorías de la BD, usadas para filtrar.
const CATEGORIES = [
  { name: 'Tarjetas Madres',   emoji: '🖥️', count: 3 },
  { name: 'Tarjetas Gráficas', emoji: '🎮', count: 3 },
  { name: 'Procesadores',      emoji: '⚙️', count: 3 },
  { name: 'Memorias RAM',      emoji: '💾', count: 3 },
  { name: 'Almacenamiento',    emoji: '💿', count: 4 },
  { name: 'Periféricos',       emoji: '🎧', count: 4 },
];

// ─── Cargar productos desde la API ───────────────────────────
// Se ejecuta al cargar cada página (en su DOMContentLoaded).
async function loadProducts() {
  try {
    const res = await fetch('api/productos.php');
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    PRODUCTS = await res.json();
  } catch (err) {
    console.error('Error cargando productos:', err);
    showToast('Error al cargar el catálogo. Verifica que XAMPP esté corriendo.', 'error');
  }
}

// ─── Estado global del carrito ──────────────────────────────
// Se restaura desde localStorage al iniciar.
let cart            = JSON.parse(localStorage.getItem('innovatech_cart') || '[]');
let selectedCategory = 'all';
let selectedPayment  = 'efectivo';

// ─── Persistir carrito en localStorage ───────────────────────
function saveCart() {
  localStorage.setItem('innovatech_cart', JSON.stringify(cart));
  updateCartCount();
}

// ─── Actualizar badge del carrito en la navbar ───────────────
// La animación .bump da feedback visual al usuario.
function updateCartCount() {
  const el = document.getElementById('cartCount');
  if (!el) return;
  const total = cart.reduce((acc, item) => acc + item.qty, 0);
  el.textContent = total;
  el.classList.remove('bump');
  void el.offsetWidth;  // Forzar reflow para reiniciar animación
  el.classList.add('bump');
}

// ═════════════════════════════════════════════════════════════
//  HELPERS DE USUARIO Y AUTENTICACIÓN
// ═════════════════════════════════════════════════════════════

// ─── Obtener usuario desde localStorage ──────────────────────
function getUser() {
  try { return JSON.parse(localStorage.getItem('it_user')); } catch { return null; }
}

// ─── Forzar autenticación ────────────────────────────────────
// Si no hay sesión, guarda la URL actual y redirige al login.
// Útil para páginas que requieren login (checkout, etc.).
function requireAuth(msg) {
  const user = getUser();
  if (!user) {
    localStorage.setItem('redirectAfterLogin', window.location.href);
    showToast(msg || 'Debes iniciar sesión para continuar', 'error');
    setTimeout(() => { location.href = 'login.html'; }, 1200);
    return null;
  }
  return user;
}

// ═════════════════════════════════════════════════════════════
//  CARRITO DE COMPRAS (con restricción para visitantes)
// ═════════════════════════════════════════════════════════════

// ─── Agregar producto al carrito ─────────────────────────────
// Visitantes: no pueden agregar, se les redirige al login.
function addToCart(productId) {
  const user = getUser();
  if (!user) {
    showToast('Debes iniciar sesión para agregar productos al carrito', 'error');
    localStorage.setItem('redirectAfterLogin', window.location.href);
    setTimeout(() => { location.href = 'login.html'; }, 1500);
    return;
  }

  const product = PRODUCTS.find(p => p.id === productId);
  if (!product || !product.inStock) return;

  // Si el producto ya está en el carrito, aumentar cantidad
  const existing = cart.find(item => item.id === productId);
  if (existing) {
    existing.qty++;
  } else {
    cart.push({
      id:     product.id,
      name:   product.name,
      cat:    product.cat,
      emoji:  product.emoji,
      imagen: product.imagen_url || null,
      price:  product.price,
      qty:    1
    });
  }

  saveCart();
  showToast(`✓ ${product.name.split(' ').slice(0, 3).join(' ')} agregado al carrito`);
}

// ─── Toggle menú móvil ───────────────────────────────────────
function toggleMobile() {
  const nav = document.getElementById('mobileNav');
  if (nav) nav.classList.toggle('open');
}

// ═════════════════════════════════════════════════════════════
//  PÁGINA DE INICIO — Categorías y Destacados
// ═════════════════════════════════════════════════════════════

// ─── Renderizar tarjetas de categorías en home ───────────────
function renderHomeCategories() {
  const el = document.getElementById('homeCategories');
  if (!el) return;
  el.innerHTML = CATEGORIES.map(cat => `
    <div class="cat-card" onclick="goToCatalogCat('${cat.name}')">
      <span class="cat-icon">${cat.emoji}</span>
      <div class="cat-name">${cat.name}</div>
      <div class="cat-count">${cat.count} productos</div>
    </div>
  `).join('');
}

// ─── Navegar al catálogo filtrado por categoría ──────────────
// Guarda la categoría en localStorage para que catalogo.html la lea.
function goToCatalogCat(catName) {
  localStorage.setItem('filtroCategoria', catName);
  location.href = 'catalogo.html';
}

// ─── Renderizar productos destacados en home ─────────────────
function renderFeatured() {
  const el = document.getElementById('featuredProducts');
  if (!el) return;
  const featured = PRODUCTS.filter(p => p.featured);
  el.innerHTML = featured.map(p => productCard(p)).join('');
}

// ═════════════════════════════════════════════════════════════
//  CATÁLOGO — Filtros y búsqueda
// ═════════════════════════════════════════════════════════════

// ─── Renderizar filtros de categoría (radio buttons) ─────────
function renderCatalogFilters() {
  const el = document.getElementById('catFilters');
  if (!el) return;
  el.innerHTML = `
    <div class="filter-option ${selectedCategory === 'all' ? 'selected' : ''}"
         onclick="setCatFilter('all')">
      <input type="radio" name="catFilter" ${selectedCategory === 'all' ? 'checked' : ''}>
      Todas las categorías
    </div>
    ${CATEGORIES.map(cat => `
      <div class="filter-option ${selectedCategory === cat.name ? 'selected' : ''}"
           onclick="setCatFilter('${cat.name}')">
        <input type="radio" name="catFilter"
               ${selectedCategory === cat.name ? 'checked' : ''}>
        ${cat.emoji} ${cat.name}
      </div>
    `).join('')}
  `;
}

// ─── Cambiar filtro de categoría y re-renderizar ─────────────
function setCatFilter(cat) {
  selectedCategory = cat;
  renderCatalogFilters();
  filterProducts();
}

// ─── Filtro completo (búsqueda, precio, stock, ofertas, orden) ─
function filterProducts() {
  const grid  = document.getElementById('catalogGrid');
  const count = document.getElementById('catalogCount');
  if (!grid) return;

  const query    = (document.getElementById('searchInput')?.value || '').toLowerCase();
  const minPx    = parseFloat(document.getElementById('priceMin')?.value)  || 0;
  const maxPx    = parseFloat(document.getElementById('priceMax')?.value)  || Infinity;
  const inStock  = document.getElementById('inStockOnly')?.checked;
  const saleOnly = document.getElementById('saleOnly')?.checked;
  const sort     = document.getElementById('sortSelect')?.value || 'default';

  // Aplicar filtros
  let results = PRODUCTS.filter(p => {
    if (selectedCategory !== 'all' && p.cat !== selectedCategory) return false;
    if (query && !p.name.toLowerCase().includes(query) &&
                 !p.cat.toLowerCase().includes(query))             return false;
    if (p.price < minPx || p.price > maxPx)                       return false;
    if (inStock  && !p.inStock)                                    return false;
    if (saleOnly && !p.oldPrice)                                   return false;
    return true;
  });

  // Ordenar resultados
  if (sort === 'price-asc')  results.sort((a, b) => a.price - b.price);
  if (sort === 'price-desc') results.sort((a, b) => b.price - a.price);
  if (sort === 'name-asc')   results.sort((a, b) => a.name.localeCompare(b.name));

  // Renderizar grid o mensaje vacío
  grid.innerHTML = results.length
    ? results.map(p => productCard(p)).join('')
    : '<p style="color:var(--text-muted);grid-column:1/-1;padding:40px;text-align:center;">No se encontraron productos.</p>';

  if (count) count.innerHTML =
    `<strong>${results.length}</strong> de <strong>${PRODUCTS.length}</strong> productos`;
}

// ═════════════════════════════════════════════════════════════
//  TARJETA DE PRODUCTO (componente reutilizable)
// ═════════════════════════════════════════════════════════════

// ─── Genera el HTML de una tarjeta de producto ──────────────
// Maneja: badge promocional, precio anterior tachado, stock,
// botón agregar (deshabilitado si sin stock), imagen local con
// fallback a emoji si la imagen no carga.
function productCard(p) {
  const badgeHtml = p.badge
    ? `<span class="badge badge-${p.badgeType} product-badge-corner">${p.badge}</span>`
    : '';
  const oldPriceHtml = p.oldPrice
    ? `<span style="font-size:13px;color:var(--text-muted);text-decoration:line-through;display:block;margin-bottom:2px;">$${p.oldPrice}</span>`
    : '';
  const stockHtml = !p.inStock
    ? `<span class="badge badge-rojo" style="display:block;margin-bottom:8px;">Sin stock</span>`
    : '';
  const addBtnHtml = p.inStock
    ? `<button class="add-btn" onclick="addToCart('${p.id}')">
         <i class='bx bx-cart-add'></i> Agregar
       </button>`
    : `<button class="add-btn" style="background:var(--border);cursor:not-allowed;" disabled>Sin stock</button>`;

  // Imagen local con fallback a emoji si no carga
  const imagenHtml = p.imagen_url
    ? `<img src="img/productos/${p.imagen_url}" alt="${p.name}"
           style="width:100%;height:100%;object-fit:cover;"
           onerror="this.style.display='none';this.nextElementSibling.style.display='flex';" />
       <span style="display:none;font-size:64px;width:100%;height:100%;align-items:center;justify-content:center;">${p.emoji}</span>`
    : `<span style="font-size:64px;">${p.emoji}</span>`;

  return `
    <div class="product-card">
      <div class="product-img" style="overflow:hidden;padding:0;position:relative;">
        ${badgeHtml}
        ${imagenHtml}
      </div>
      <div class="product-info">
        <div class="product-cat">${p.cat}</div>
        <div class="product-name">${p.name}</div>
        <div class="product-specs">${p.specs}</div>
        ${stockHtml}
        <div class="product-bottom">
          <div>
            ${oldPriceHtml}
            <div class="product-price">$${p.price}</div>
          </div>
          ${addBtnHtml}
        </div>
      </div>
    </div>
  `;
}

// ═════════════════════════════════════════════════════════════
//  CARRITO — Helpers (usados desde carrito.html)
// ═════════════════════════════════════════════════════════════

// ─── Cambiar cantidad de un item (delta: +1 o -1) ──────────
function changeQty(productId, delta) {
  const item = cart.find(i => i.id === productId);
  if (!item) return;
  item.qty = Math.max(1, item.qty + delta);
  saveCart();
  if (typeof renderCart === 'function') renderCart();
}

// ─── Eliminar un item del carrito ────────────────────────────
function removeFromCart(productId) {
  cart = cart.filter(i => i.id !== productId);
  saveCart();
  if (typeof renderCart === 'function') renderCart();
  showToast('Producto eliminado del carrito', 'error');
}

// ═════════════════════════════════════════════════════════════
//  CHECKOUT — Método de pago y envío del pedido
// ═════════════════════════════════════════════════════════════

// ─── Seleccionar método de pago ──────────────────────────────
function selectPayment(el) {
  document.querySelectorAll('.payment-method').forEach(m => m.classList.remove('selected'));
  el.classList.add('selected');
  selectedPayment = el.dataset.method;
}

// ─── Enviar pedido a la API ─────────────────────────────────
// Solo ejecutable por usuarios logueados.
async function placeOrder() {
  const user = getUser();
  if (!user) {
    showToast('Debes iniciar sesión para completar la compra', 'error');
    setTimeout(() => { location.href = 'login.html'; }, 1200);
    return;
  }

  // Leer campos del formulario de checkout
  const nombre    = document.getElementById('chkNombre')?.value.trim();
  const tel       = document.getElementById('chkTelefono')?.value.trim();
  const email     = document.getElementById('chkEmail')?.value.trim();
  const direccion = document.getElementById('chkDireccion')?.value.trim();
  const ciudad    = document.getElementById('chkCiudad')?.value.trim();
  const dpto      = document.getElementById('chkDpto')?.value.trim();
  const notas     = document.getElementById('chkNotas')?.value.trim();

  if (!nombre || !tel || !email || !direccion) {
    showToast('Por favor completa todos los campos requeridos', 'error');
    return;
  }
  if (cart.length === 0) {
    showToast('Tu carrito está vacío', 'error');
    return;
  }

  try {
    const res  = await fetch('api/pedidos.php', {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        cliente: { nombre, email, telefono: tel, direccion, ciudad, departamento: dpto, notas, metodoPago: selectedPayment},
        items: cart
      })
    });
    const data = await res.json();

    if (data.ok) {
      cart = [];
      saveCart();
      const modalDesc = document.getElementById('modalDesc');
      if (modalDesc) {
        modalDesc.textContent =
          `Pedido ${data.numero_orden} confirmado. Total: $${parseFloat(data.total).toFixed(2)}. ¡Gracias por elegir InnovaTech!`;
      }
      const modal = document.getElementById('successModal');
      if (modal) modal.classList.add('open');
    } else {
      showToast(data.error || 'Error al procesar el pedido', 'error');
    }
  } catch (err) {
    showToast('Error de conexión — verifica que XAMPP esté corriendo', 'error');
    console.error(err);
  }
}

// ═════════════════════════════════════════════════════════════
//  CONTACTO — Envío de mensaje (público)
// ═════════════════════════════════════════════════════════════

// ─── Enviar mensaje de contacto a la API ─────────────────────
async function sendContact() {
  const nombre  = document.getElementById('ctcNombre')?.value.trim();
  const email   = document.getElementById('ctcEmail')?.value.trim();
  const tel     = document.getElementById('ctcTel')?.value.trim();
  const asunto  = document.getElementById('ctcAsunto')?.value.trim();
  const mensaje = document.getElementById('ctcMsg')?.value.trim();

  if (!nombre || !email || !mensaje) {
    showToast('Por favor completa nombre, email y mensaje', 'error');
    return;
  }

  try {
    const res  = await fetch('api/contacto.php', {
      method:  'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ nombre, email, telefono: tel, asunto, mensaje })
    });
    const data = await res.json();

    if (data.ok) {
      // Limpiar formulario
      ['ctcNombre','ctcTel','ctcEmail','ctcAsunto','ctcMsg'].forEach(id => {
        const el = document.getElementById(id);
        if (el) el.value = '';
      });
      showToast('¡Mensaje enviado! Te responderemos pronto.');
    } else {
      showToast(data.error || 'Error al enviar el mensaje', 'error');
    }
  } catch (err) {
    showToast('Error de conexión — verifica que XAMPP esté corriendo', 'error');
    console.error(err);
  }
}

// ═════════════════════════════════════════════════════════════
//  TOAST — Notificaciones emergentes
// ═════════════════════════════════════════════════════════════

// ─── Mostrar toast (success o error) ─────────────────────────
// Crea un elemento toast en el contenedor y lo elimina tras 3s.
function showToast(msg, type = 'success') {
  const container = document.getElementById('toastContainer');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = 'toast';
  toast.style.borderColor = type === 'error' ? 'var(--error)' : 'var(--success)';
  toast.style.color       = type === 'error' ? 'var(--error)' : 'var(--success)';
  toast.innerHTML = `
    <i class='bx ${type === 'error' ? 'bx-x-circle' : 'bx-check-circle'}'
       style="font-size:18px;"></i> ${msg}
  `;
  container.appendChild(toast);

  // Auto-eliminar después de 3 segundos
  setTimeout(() => {
    toast.style.animation = 'slideOut .3s ease both';
    setTimeout(() => toast.remove(), 300);
  }, 3000);
}

// ═════════════════════════════════════════════════════════════
//  SESIÓN — UI en la navbar
// ═════════════════════════════════════════════════════════════

// ─── Inicializar UI de sesión (IIFE) ───────────────────────
// Se ejecuta al cargar app.js.
// Muestra:
//   - Si NO hay sesión: botón "Ingresar"
//   - Si hay sesión: nombre + badge Admin + logout
//   - Si el rol es 'admin': enlace al panel de administración
(function initSession() {
  const user     = getUser();
  const actionsEl = document.querySelector('.nav-actions');
  if (!actionsEl) return;

  if (user) {
    const wrapper = document.createElement('div');
    wrapper.className = 'user-session';
    const rolBadge = user.rol === 'admin' ? `<span class="user-rol">Admin</span>` : '';
    wrapper.innerHTML = `
      <span class="user-name">
        <i class='bx bx-user-circle'></i> ${user.nombre.split(' ')[0]}${rolBadge}
      </span>
      <button class="logout-btn" onclick="cerrarSesion()" title="Cerrar sesión">
        <i class='bx bx-log-out'></i>
      </button>
    `;
    // Mostrar enlace al panel admin solo si el usuario es admin
    if (user.rol === 'admin') {
      const adminLink = document.createElement('a');
      adminLink.href      = 'admin.html';
      adminLink.className = 'admin-nav-btn';
      adminLink.innerHTML = '<i class="bx bx-shield"></i> Admin';
      actionsEl.prepend(adminLink);
    }
    actionsEl.prepend(wrapper);
  } else {
    const loginBtn = document.createElement('a');
    loginBtn.href      = 'login.html';
    loginBtn.className = 'login-nav-btn';
    loginBtn.innerHTML = `<i class='bx bx-user'></i> Ingresar`;
    actionsEl.prepend(loginBtn);
  }
})();

// ─── Cerrar sesión ──────────────────────────────────────────
// Elimina el usuario de localStorage y recarga en el home.
function cerrarSesion() {
  localStorage.removeItem('it_user');
  location.href = 'index.html';
}
