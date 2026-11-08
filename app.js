// OpenApps — Lógica de catálogo, auditoría, PWA y blindaje de seguridad
// Sin dependencias externas, sin analíticas ni cookies.

document.addEventListener('DOMContentLoaded', () => {
  const target = document.getElementById('catalog');
  if (!target) return;

  fetch('./apps/catalog.json')
    .then(res => {
      if (!res.ok) throw new Error('No se pudo cargar el catálogo');
      return res.json();
    })
    .then(apps => {
      if (!Array.isArray(apps) || !apps.length) {
        target.innerHTML = '<p class="muted">No hay aplicaciones registradas en este momento.</p>';
        return;
      }

      target.innerHTML = '';
      for (const app of apps) {
        target.appendChild(createAppCard(app));
      }
    })
    .catch(() => {
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
  icon.textContent = sanitizeText(app.icon || app.name?.charAt(0) || '◈');
  icon.setAttribute('aria-label', `Icono de ${sanitizeText(app.name)}`);

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
    cat.textContent = sanitizeText(app.category);
    meta.appendChild(cat);
  }

  const title = document.createElement('h3');
  title.textContent = sanitizeText(app.name);
  meta.appendChild(title);

  if (app.version) {
    const version = document.createElement('span');
    version.className = 'app-version';
    version.textContent = sanitizeText(app.version);
    meta.appendChild(version);
  }

  top.append(icon, meta);

  // Descripción
  const desc = document.createElement('p');
  desc.className = 'app-desc';
  desc.textContent = sanitizeText(app.description);

  // Bloque de Auditoría y Privacidad
  const audit = document.createElement('div');
  audit.className = 'app-audit';
  
  const trackersCount = app.audit && typeof app.audit.trackers === 'number' ? app.audit.trackers : 0;
  const permissionsText = app.audit?.permissions || 'Sin permisos invasivos';
  const licenseText = app.audit?.license || 'Código Abierto';

  const row1 = document.createElement('div');
  row1.className = 'audit-row';
  row1.innerHTML = `<span>🛡️ Rastreadores:</span> <span class="audit-tag">${trackersCount} detectados</span>`;

  const row2 = document.createElement('div');
  row2.className = 'audit-row';
  const spanPermLabel = document.createElement('span');
  spanPermLabel.textContent = '🔑 Permisos: ';
  const spanPermVal = document.createElement('span');
  spanPermVal.textContent = sanitizeText(permissionsText);
  row2.append(spanPermLabel, spanPermVal);

  const row3 = document.createElement('div');
  row3.className = 'audit-row';
  const spanLicLabel = document.createElement('span');
  spanLicLabel.textContent = '📜 Licencia: ';
  const spanLicVal = document.createElement('span');
  spanLicVal.textContent = sanitizeText(licenseText);
  row3.append(spanLicLabel, spanLicVal);

  audit.append(row1, row2, row3);

  // Nota informativa / de prueba
  let noteEl = null;
  if (app.note) {
    noteEl = document.createElement('p');
    noteEl.className = 'app-note';
    noteEl.textContent = sanitizeText(app.note);
  }

  // Acciones (Web PWA, Descarga APK, Código Fuente)
  const actions = document.createElement('div');
  actions.className = 'app-actions';

  if (app.webUrl && isValidSafeUrl(app.webUrl)) {
    const webBtn = document.createElement('a');
    webBtn.className = 'button button-primary';
    webBtn.href = app.webUrl;
    webBtn.textContent = '🌐 Abrir Web PWA';
    actions.appendChild(webBtn);
  }

  if (app.apk && isValidSafeUrl(app.apk)) {
    const apkBtn = document.createElement('a');
    apkBtn.className = app.webUrl ? 'button button-outline' : 'button button-primary';
    apkBtn.href = app.apk;
    apkBtn.target = '_blank';
    apkBtn.rel = 'noopener noreferrer';
    apkBtn.textContent = sanitizeText(app.downloadLabel || '📦 Descargar APK');
    actions.appendChild(apkBtn);
  }

  if (app.source && isValidSafeUrl(app.source)) {
    const srcBtn = document.createElement('a');
    srcBtn.className = 'button button-subtle';
    srcBtn.href = app.source;
    srcBtn.target = '_blank';
    srcBtn.rel = 'noopener noreferrer';
    srcBtn.textContent = 'Código ↗';
    actions.appendChild(srcBtn);
  }

  // Checksum SHA-256 verificado con sanitizado hex
  if (app.sha256 && /^[a-fA-F0-9]{64}$/.test(app.sha256)) {
    const hash = app.sha256;
    const shortHash = `${hash.substring(0, 10)}...${hash.substring(hash.length - 8)}`;

    const hashBox = document.createElement('div');
    hashBox.className = 'checksum-box';

    const hashLabel = document.createElement('span');
    hashLabel.textContent = 'SHA-256:';

    const copyBtn = document.createElement('button');
    copyBtn.type = 'button';
    copyBtn.className = 'checksum-btn';
    copyBtn.title = 'Copiar hash completo';
    copyBtn.textContent = shortHash;

    copyBtn.addEventListener('click', () => {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(hash).then(() => {
          copyBtn.textContent = '¡Copiado!';
          setTimeout(() => { copyBtn.textContent = shortHash; }, 1500);
        });
      }
    });

    hashBox.append(hashLabel, copyBtn);
    actions.appendChild(hashBox);
  }

  // Ensamblado en DOM seguro
  card.appendChild(top);
  card.appendChild(desc);
  card.appendChild(audit);
  if (noteEl) card.appendChild(noteEl);
  card.appendChild(actions);

  return card;
}

function sanitizeText(str) {
  if (str === null || str === undefined) return '';
  return String(str);
}

function isValidSafeUrl(url) {
  try {
    const parsed = new URL(url, window.location.href);
    return ['http:', 'https:'].includes(parsed.protocol);
  } catch {
    return false;
  }
}
