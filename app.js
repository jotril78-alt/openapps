// OpenApps — Lógica de catálogo, auditoría, PWA y utilidades criptográficas
// Sin dependencias, sin analíticas y sin cookies.

document.addEventListener('DOMContentLoaded', () => {
  const target = document.getElementById('catalog');
  if (!target) return;

  fetch('./apps/catalog.json')
    .then(res => {
      if (!res.ok) throw new Error('No se pudo cargar el catálogo');
      return res.json();
    })
    .then(apps => {
      if (!apps || !apps.length) {
        target.innerHTML = '<p class="muted">No hay aplicaciones registradas en este momento.</p>';
        return;
      }

      target.innerHTML = '';
      for (const app of apps) {
        target.appendChild(createAppCard(app));
      }
    })
    .catch(err => {
      target.innerHTML = `
        <div style="background: #23161c; border: 1px solid #5a2732; padding: 20px; border-radius: 12px; grid-column: 1 / -1;">
          <p style="margin:0 0 10px; color:#ff98a2;">⚠️ Error al leer el catálogo de aplicaciones.</p>
          <small class="muted">Si estás abriendo el archivo localmente como <code>file://</code>, inicia un servidor estático local (ej. <code>python -m http.server 8000</code>).</small>
        </div>
      `;
    });
});

function createAppCard(app) {
  const card = document.createElement('article');
  card.className = 'app-card';

  // Cabecera de la tarjeta
  const top = document.createElement('div');
  top.className = 'app-top';

  const icon = document.createElement('div');
  icon.className = 'app-icon';
  icon.textContent = app.icon || app.name.charAt(0);
  icon.setAttribute('aria-label', `Icono de ${app.name}`);

  if (app.status === 'test') {
    const ribbon = document.createElement('span');
    ribbon.className = 'test-ribbon';
    ribbon.textContent = 'TEST';
    icon.appendChild(ribbon);
  }

  const meta = document.createElement('div');
  meta.className = 'app-meta';

  if (app.category) {
    const cat = document.createElement('span');
    cat.className = 'app-category';
    cat.textContent = app.category;
    meta.appendChild(cat);
  }

  const title = document.createElement('h3');
  title.textContent = app.name;
  meta.appendChild(title);

  if (app.version) {
    const version = document.createElement('span');
    version.className = 'app-version';
    version.textContent = app.version;
    meta.appendChild(version);
  }

  top.append(icon, meta);

  // Descripción
  const desc = document.createElement('p');
  desc.className = 'app-desc';
  desc.textContent = app.description;

  // Bloque de Auditoría y Privacidad
  const audit = document.createElement('div');
  audit.className = 'app-audit';
  
  const trackersCount = app.audit && typeof app.audit.trackers === 'number' ? app.audit.trackers : 0;
  const permissionsText = app.audit?.permissions || 'Sin permisos invasivos';
  const licenseText = app.audit?.license || 'Código Abierto';

  audit.innerHTML = `
    <div class="audit-row"><span>🛡️ Rastreadores:</span> <span class="audit-tag">${trackersCount} detectados</span></div>
    <div class="audit-row"><span>🔑 Permisos:</span> <span>${escapeHtml(permissionsText)}</span></div>
    <div class="audit-row"><span>📜 Licencia:</span> <span>${escapeHtml(licenseText)}</span></div>
  `;

  // Nota de versión / test si existe
  let noteEl = null;
  if (app.note) {
    noteEl = document.createElement('p');
    noteEl.className = 'app-note';
    noteEl.textContent = app.note;
  }

  // Acciones (Web PWA, Descarga APK, Código Fuente)
  const actions = document.createElement('div');
  actions.className = 'app-actions';

  if (app.webUrl) {
    const webBtn = document.createElement('a');
    webBtn.className = 'button button-primary';
    webBtn.href = app.webUrl;
    webBtn.textContent = '🌐 Abrir Web PWA';
    actions.appendChild(webBtn);
  }

  if (app.apk) {
    const apkBtn = document.createElement('a');
    apkBtn.className = app.webUrl ? 'button button-outline' : 'button button-primary';
    apkBtn.href = app.apk;
    apkBtn.target = '_blank';
    apkBtn.rel = 'noopener noreferrer';
    apkBtn.textContent = app.downloadLabel || '📦 Descargar APK';
    actions.appendChild(apkBtn);
  }

  if (app.source) {
    const srcBtn = document.createElement('a');
    srcBtn.className = 'button button-subtle';
    srcBtn.href = app.source;
    srcBtn.target = '_blank';
    srcBtn.rel = 'noopener noreferrer';
    srcBtn.textContent = 'Código ↗';
    actions.appendChild(srcBtn);
  }

  // Checksum SHA-256 si está presente
  if (app.sha256) {
    const hashBox = document.createElement('div');
    hashBox.className = 'checksum-box';
    const shortHash = `${app.sha256.substring(0, 10)}...${app.sha256.substring(app.sha256.length - 8)}`;
    hashBox.innerHTML = `
      <span>SHA-256:</span>
      <button type="button" class="checksum-btn" title="Copiar hash completo" onclick="navigator.clipboard.writeText('${app.sha256}').then(() => { this.textContent = '¡Copiado!'; setTimeout(() => { this.textContent = '${shortHash}'; }, 1500); })">
        ${shortHash}
      </button>
    `;
    actions.appendChild(hashBox);
  }

  // Ensamblado
  card.appendChild(top);
  card.appendChild(desc);
  card.appendChild(audit);
  if (noteEl) card.appendChild(noteEl);
  card.appendChild(actions);

  return card;
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
