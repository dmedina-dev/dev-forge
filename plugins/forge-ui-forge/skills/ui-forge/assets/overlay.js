/**
 * ui-forge overlay.js
 * Sistema de anotación inline para 02-forge.html
 *
 * Inyectar entre marcadores:
 *   <!-- ui-forge:overlay:start -->
 *   <script>...este fichero...</script>
 *   <!-- ui-forge:overlay:end -->
 *
 * Para destilar (Fase 4): strip todo lo que hay entre los marcadores.
 *
 * Requiere en el documento:
 *   - <div id="uiforge-root"></div>           (contenedor de la pantalla)
 *   - window.UIFORGE_SCREEN_ID = "<screen-id>"
 *   - window.UIFORGE_SCENARIOS = ["happy", "empty", "loading", "error", ...]
 *   - window.UIFORGE_DATA = { happy: {...}, empty: {...}, ... }
 *   - función render(data) global que pinta la UI con un objeto de datos
 *
 * Atajos:
 *   - A → toggle modo anotación
 *   - P → toggle panel de pins
 */

(function () {
  'use strict';

  const STORAGE_KEY = `uiforge:${window.UIFORGE_SCREEN_ID || 'unknown'}:pins`;
  const SCENARIO_KEY = `uiforge:${window.UIFORGE_SCREEN_ID || 'unknown'}:scenario`;
  const ROUNDS_KEY = STORAGE_KEY + ':rounds';

  const PIN_TYPES = {
    change: { color: '#3b82f6', label: 'Cambio' },
    'extract-as-component': { color: '#10b981', label: 'Extraer como componente' },
    'replace-with-registry': { color: '#8b5cf6', label: 'Reemplazar con registry' },
    'token-issue': { color: '#f59e0b', label: 'Problema de token' },
    'data-issue': { color: '#ef4444', label: 'Problema de datos' },
  };

  let pins = [];
  let currentScenario = 'happy';
  let pinIdCounter = 1;
  let annotating = false;
  let panelOpen = false;

  function loadState() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const parsed = JSON.parse(raw);
        pins = parsed.pins || [];
        pinIdCounter = (pins.reduce((m, p) => Math.max(m, p.id), 0) || 0) + 1;
      }
      currentScenario = localStorage.getItem(SCENARIO_KEY) || 'happy';
    } catch (e) { console.warn('[ui-forge] load failed', e); }
  }

  function saveState() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify({ pins }));
      localStorage.setItem(SCENARIO_KEY, currentScenario);
    } catch (e) { console.warn('[ui-forge] save failed', e); }
  }

  function getSelector(el) {
    if (!el || el.nodeType !== 1) return '';
    if (el.id) return `#${el.id}`;
    const path = [];
    let node = el;
    while (node && node.nodeType === 1 && node !== document.body) {
      let segment = node.nodeName.toLowerCase();
      if (node.classList.length) {
        segment += '.' + Array.from(node.classList).slice(0, 2).join('.');
      }
      const parent = node.parentNode;
      if (parent) {
        const siblings = Array.from(parent.children).filter((c) => c.nodeName === node.nodeName);
        if (siblings.length > 1) {
          segment += `:nth-of-type(${siblings.indexOf(node) + 1})`;
        }
      }
      path.unshift(segment);
      node = parent;
    }
    return path.join(' > ');
  }

  function injectStyles() {
    const css = `
      #uiforge-fab {
        position: fixed; bottom: 20px; right: 20px;
        width: 56px; height: 56px; border-radius: 50%;
        background: #3b82f6; color: white; border: none;
        font-size: 22px; cursor: pointer; z-index: 999999;
        box-shadow: 0 4px 14px rgba(0,0,0,.35);
        display: flex; align-items: center; justify-content: center;
        transition: transform .15s ease, background .15s ease;
      }
      #uiforge-fab:hover { transform: scale(1.06); background: #2563eb; }
      #uiforge-fab.annotating { background: #ef4444; }
      #uiforge-fab.annotating:hover { background: #dc2626; }
      #uiforge-fab-badge {
        position: absolute; top: -4px; right: -4px;
        background: #0f172a; color: white; font-size: 11px;
        min-width: 20px; height: 20px; border-radius: 10px;
        display: flex; align-items: center; justify-content: center;
        padding: 0 6px; font-weight: 600; border: 2px solid white;
      }
      #uiforge-fab-badge.hidden { display: none; }
      #uiforge-panel {
        position: fixed; top: 0; right: 0; width: 380px; height: 100vh;
        background: #0f172a; color: #e2e8f0;
        font-family: ui-sans-serif, system-ui, sans-serif; font-size: 13px;
        z-index: 999998; overflow-y: auto;
        box-shadow: -4px 0 24px rgba(0,0,0,.4); padding: 16px;
        transform: translateX(100%); transition: transform .2s ease;
        box-sizing: border-box;
      }
      #uiforge-panel.open { transform: translateX(0); }
      #uiforge-panel header {
        display: flex; justify-content: space-between; align-items: center;
        margin-bottom: 12px;
      }
      #uiforge-panel h2 { font-size: 14px; margin: 0; font-weight: 600; }
      #uiforge-close {
        background: transparent; color: #94a3b8; border: none;
        font-size: 20px; cursor: pointer; padding: 0 4px;
      }
      #uiforge-close:hover { color: #e2e8f0; }
      #uiforge-panel .row { display: flex; gap: 8px; margin-bottom: 12px; }
      #uiforge-panel button {
        background: #1e293b; color: #e2e8f0; border: 1px solid #334155;
        padding: 6px 10px; border-radius: 4px; cursor: pointer; font-size: 12px;
      }
      #uiforge-panel button:hover:not(:disabled) { background: #334155; }
      #uiforge-panel button:disabled { opacity: .4; cursor: not-allowed; }
      #uiforge-panel button.primary { background: #3b82f6; border-color: #3b82f6; }
      #uiforge-panel button.primary:hover:not(:disabled) { background: #2563eb; }
      #uiforge-panel button.danger { background: #7f1d1d; border-color: #991b1b; }
      #uiforge-panel button.danger:hover:not(:disabled) { background: #991b1b; }
      #uiforge-panel select {
        background: #1e293b; color: #e2e8f0; border: 1px solid #334155;
        padding: 6px; border-radius: 4px; width: 100%; font-size: 12px;
      }
      #uiforge-meta { font-size: 11px; color: #94a3b8; margin-bottom: 8px; }
      #uiforge-pins-list { list-style: none; padding: 0; margin: 0; }
      #uiforge-pins-list li {
        background: #1e293b; padding: 8px; border-radius: 4px;
        margin-bottom: 6px; border-left: 3px solid #3b82f6;
      }
      #uiforge-pins-list .pin-meta {
        font-size: 11px; color: #94a3b8; margin-bottom: 4px;
        display: flex; justify-content: space-between;
      }
      #uiforge-pins-list .pin-comment {
        background: #0f172a; border: 1px solid #334155; color: #e2e8f0;
        width: 100%; box-sizing: border-box; resize: vertical;
        font-family: inherit; font-size: 12px; padding: 4px;
        border-radius: 3px;
      }
      #uiforge-pins-list .pin-actions { display: flex; gap: 4px; margin-top: 4px; }
      #uiforge-empty {
        color: #64748b; font-size: 12px; text-align: center;
        padding: 20px 0; font-style: italic;
      }
      .uiforge-pin {
        position: absolute; width: 24px; height: 24px; border-radius: 50%;
        color: white; font-weight: bold; font-size: 12px; display: flex;
        align-items: center; justify-content: center; cursor: pointer;
        z-index: 999997; transform: translate(-50%, -50%);
        border: 2px solid white; box-shadow: 0 2px 6px rgba(0,0,0,.4);
      }
      body.uiforge-annotating { cursor: crosshair !important; }
      body.uiforge-annotating #uiforge-root * { cursor: crosshair !important; }
    `;
    const style = document.createElement('style');
    style.textContent = css;
    document.head.appendChild(style);
  }

  function renderFab() {
    let fab = document.getElementById('uiforge-fab');
    if (!fab) {
      fab = document.createElement('button');
      fab.id = 'uiforge-fab';
      fab.title = 'ui-forge — click: panel · A: anotar · P: panel';
      fab.innerHTML = `<span>📍</span><span id="uiforge-fab-badge" class="hidden">0</span>`;
      fab.addEventListener('click', togglePanel);
      document.body.appendChild(fab);
    }
    fab.classList.toggle('annotating', annotating);
    const badge = document.getElementById('uiforge-fab-badge');
    if (pins.length > 0) {
      badge.textContent = pins.length;
      badge.classList.remove('hidden');
    } else {
      badge.classList.add('hidden');
    }
  }

  function togglePanel() {
    panelOpen = !panelOpen;
    if (panelOpen) renderPanel();
    const panel = document.getElementById('uiforge-panel');
    if (panel) panel.classList.toggle('open', panelOpen);
  }

  function renderPanel() {
    let panel = document.getElementById('uiforge-panel');
    if (!panel) {
      panel = document.createElement('div');
      panel.id = 'uiforge-panel';
      document.body.appendChild(panel);
    }
    const scenarios = window.UIFORGE_SCENARIOS || ['happy'];
    panel.innerHTML = `
      <header>
        <h2>ui-forge · ${escapeHtml(window.UIFORGE_SCREEN_ID || 'screen')}</h2>
        <button id="uiforge-close" title="Cerrar (P)">×</button>
      </header>
      <div>
        <label style="font-size:11px;color:#94a3b8">Escenario</label>
        <select id="uiforge-scenario">
          ${scenarios.map((s) => `<option value="${s}" ${s === currentScenario ? 'selected' : ''}>${s}</option>`).join('')}
        </select>
      </div>
      <div class="row" style="margin-top:12px">
        <button id="uiforge-toggle" class="${annotating ? 'danger' : 'primary'}">
          ${annotating ? 'Salir (A)' : 'Anotar (A)'}
        </button>
        <button id="uiforge-copy" title="Copiar JSON al portapapeles" ${pins.length === 0 ? 'disabled' : ''}>📋</button>
        <button id="uiforge-download" title="Descargar JSON" ${pins.length === 0 ? 'disabled' : ''}>⬇</button>
        <button id="uiforge-clear" class="danger" ${pins.length === 0 ? 'disabled' : ''}>Clear</button>
      </div>
      <div id="uiforge-meta">
        ${pins.length} pin${pins.length === 1 ? '' : 's'} · próxima ronda: ${getNextRound()}
      </div>
      ${pins.length === 0
        ? '<div id="uiforge-empty">Sin anotaciones. Pulsa <b>A</b> y haz click sobre la pantalla.</div>'
        : `<ul id="uiforge-pins-list">${pins.map((p) => `
            <li style="border-left-color:${PIN_TYPES[p.type]?.color || '#3b82f6'}">
              <div class="pin-meta">
                <span>#${p.id} · ${p.scenario}</span>
                <span style="color:${PIN_TYPES[p.type]?.color}">${PIN_TYPES[p.type]?.label || p.type}</span>
              </div>
              <textarea class="pin-comment" data-pin="${p.id}" rows="2">${escapeHtml(p.comment)}</textarea>
              <div class="pin-actions">
                <select data-pin-type="${p.id}" style="flex:1;font-size:11px">
                  ${Object.entries(PIN_TYPES).map(([k, v]) => `<option value="${k}" ${k === p.type ? 'selected' : ''}>${v.label}</option>`).join('')}
                </select>
                <button data-pin-goto="${p.id}" title="Ir al pin">→</button>
                <button data-pin-delete="${p.id}" class="danger" title="Borrar">×</button>
              </div>
            </li>`).join('')}</ul>`
      }
    `;
    document.getElementById('uiforge-close').addEventListener('click', togglePanel);
    document.getElementById('uiforge-scenario').addEventListener('change', (e) => {
      currentScenario = e.target.value;
      saveState();
      applyScenario();
    });
    document.getElementById('uiforge-toggle').addEventListener('click', toggleAnnotating);
    const copyBtn = document.getElementById('uiforge-copy');
    if (copyBtn && !copyBtn.disabled) copyBtn.addEventListener('click', exportToClipboard);
    const downloadBtn = document.getElementById('uiforge-download');
    if (downloadBtn && !downloadBtn.disabled) downloadBtn.addEventListener('click', exportToDownload);
    const clearBtn = document.getElementById('uiforge-clear');
    if (clearBtn && !clearBtn.disabled) {
      clearBtn.addEventListener('click', () => {
        if (confirm(`Borrar las ${pins.length} pins acumuladas?`)) {
          pins = [];
          saveState();
          renderPins();
          renderPanel();
          renderFab();
        }
      });
    }
    panel.querySelectorAll('[data-pin]').forEach((ta) => {
      ta.addEventListener('input', (e) => {
        const id = +e.target.dataset.pin;
        const p = pins.find((x) => x.id === id);
        if (p) { p.comment = e.target.value; saveState(); }
      });
    });
    panel.querySelectorAll('[data-pin-type]').forEach((sel) => {
      sel.addEventListener('change', (e) => {
        const id = +e.target.dataset.pinType;
        const p = pins.find((x) => x.id === id);
        if (p) { p.type = e.target.value; saveState(); renderPins(); renderPanel(); }
      });
    });
    panel.querySelectorAll('[data-pin-goto]').forEach((btn) => {
      btn.addEventListener('click', (e) => {
        const id = +e.target.dataset.pinGoto;
        const p = pins.find((x) => x.id === id);
        if (p) {
          window.scrollTo({ top: p.y - window.innerHeight / 2, behavior: 'smooth' });
          const el = Array.from(document.querySelectorAll('.uiforge-pin')).find((x) => x.textContent === String(p.id));
          if (el) {
            el.style.transition = 'transform .3s';
            el.style.transform = 'translate(-50%, -50%) scale(1.8)';
            setTimeout(() => (el.style.transform = 'translate(-50%, -50%)'), 400);
          }
        }
      });
    });
    panel.querySelectorAll('[data-pin-delete]').forEach((btn) => {
      btn.addEventListener('click', (e) => {
        const id = +e.target.dataset.pinDelete;
        pins = pins.filter((p) => p.id !== id);
        saveState();
        renderPins();
        renderPanel();
        renderFab();
      });
    });
  }

  function escapeHtml(s) {
    return (s || '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
  }

  function renderPins() {
    document.querySelectorAll('.uiforge-pin').forEach((el) => el.remove());
    pins.forEach((p) => {
      const el = document.createElement('div');
      el.className = 'uiforge-pin';
      el.style.left = p.x + 'px';
      el.style.top = p.y + 'px';
      el.style.background = PIN_TYPES[p.type]?.color || '#3b82f6';
      el.textContent = p.id;
      el.title = `${PIN_TYPES[p.type]?.label || p.type}: ${p.comment}`;
      el.addEventListener('click', (e) => {
        e.stopPropagation();
        if (!panelOpen) togglePanel();
      });
      document.body.appendChild(el);
    });
  }

  function toggleAnnotating() {
    annotating = !annotating;
    document.body.classList.toggle('uiforge-annotating', annotating);
    renderFab();
    if (panelOpen) renderPanel();
  }

  function handleClick(e) {
    if (!annotating) return;
    if (e.target.closest('#uiforge-panel')) return;
    if (e.target.closest('#uiforge-fab')) return;
    if (e.target.classList.contains('uiforge-pin')) return;
    e.preventDefault();
    e.stopPropagation();
    const comment = prompt('Comentario:');
    if (!comment) return;
    const typeKeys = Object.keys(PIN_TYPES);
    const typeIdx = prompt('Tipo:\n' + typeKeys.map((k, i) => `${i + 1}. ${PIN_TYPES[k].label}`).join('\n'), '1');
    const type = typeKeys[(parseInt(typeIdx, 10) || 1) - 1] || 'change';
    const pin = {
      id: pinIdCounter++,
      selector: getSelector(e.target),
      x: e.pageX, y: e.pageY,
      viewport: { w: window.innerWidth, h: window.innerHeight },
      comment, type, scenario: currentScenario,
      timestamp: new Date().toISOString(),
    };
    pins.push(pin);
    saveState();
    renderPins();
    renderFab();
    if (panelOpen) renderPanel();
  }

  function applyScenario() {
    if (typeof window.render !== 'function') {
      console.warn('[ui-forge] window.render(data) no definida');
      return;
    }
    const data = (window.UIFORGE_DATA || {})[currentScenario];
    if (!data) {
      console.warn(`[ui-forge] escenario "${currentScenario}" no encontrado`);
      return;
    }
    window.render(data);
    setTimeout(renderPins, 50);
  }

  function getNextRound() {
    return (parseInt(localStorage.getItem(ROUNDS_KEY), 10) || 0) + 1;
  }

  function buildPayload(round) {
    return {
      screen: window.UIFORGE_SCREEN_ID,
      round,
      exportedAt: new Date().toISOString(),
      scenario: currentScenario,
      pinCount: pins.length,
      pins,
    };
  }

  function bumpRound() {
    const round = getNextRound();
    localStorage.setItem(ROUNDS_KEY, String(round));
    return round;
  }

  function exportToClipboard() {
    if (!navigator.clipboard) {
      alert('Clipboard API no disponible. Usa el botón ⬇ para descargar.');
      return;
    }
    const round = bumpRound();
    const json = JSON.stringify(buildPayload(round), null, 2);
    navigator.clipboard.writeText(json).then(
      () => {
        console.log('[ui-forge] JSON copiado');
        alert(`round-${String(round).padStart(2, '0')} copiado al portapapeles (${pins.length} pins).`);
      },
      (err) => {
        console.warn('[ui-forge] clipboard failed', err);
        alert('Fallo al copiar. Usa el botón ⬇ para descargar.');
      },
    );
  }

  function exportToDownload() {
    const round = bumpRound();
    const json = JSON.stringify(buildPayload(round), null, 2);
    const blob = new Blob([json], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `round-${String(round).padStart(2, '0')}.json`;
    a.click();
    URL.revokeObjectURL(url);
    alert(`Descargado round-${String(round).padStart(2, '0')}.json (${pins.length} pins).`);
  }

  function bindShortcuts() {
    document.addEventListener('keydown', (e) => {
      if (e.target.matches('input, textarea, select')) return;
      if (e.key === 'a' || e.key === 'A') toggleAnnotating();
      if (e.key === 'p' || e.key === 'P') togglePanel();
    });
  }

  function init() {
    loadState();
    injectStyles();
    renderFab();
    document.addEventListener('click', handleClick, true);
    window.addEventListener('resize', renderPins);
    bindShortcuts();
    applyScenario();
    renderPins();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
