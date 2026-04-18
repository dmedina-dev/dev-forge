/**
 * ui-forge overlay.js v3
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
 *
 * Modos de anotación:
 *   - Hover           → pre-highlight del elemento bajo el cursor
 *   - Click           → fija el elemento y entra en modo refine
 *   - Shift+arrastrar → área rectangular + refine desde el deepest common ancestor
 *
 * Modo refine (tras click o drag):
 *   - ↑ sube al parentElement  ·  ↓ vuelve al hijo previo (stack)
 *   - Enter abre el modal de anotación  ·  Esc cancela
 *   - HUD flotante con breadcrumb del DOM
 *
 * v2 — hot-reload (requires serve.py running on http://):
 *   - 🚀 Send to Claude → POST /forge/feedback (Monitor triggers Claude)
 *   - SSE /forge/reload → auto location.reload() when 02-forge.html changes
 *   - Falls back to clipboard/download when opened via file://
 *
 * v3 — pin history + area selection + legend:
 *   - Pins persist across rounds (sentInRound marker, dimmed rendering)
 *   - Round filter in panel (All / Pending / Round N)
 *   - Shift+drag for rectangular area selection on all pin types
 *   - Collapsible legend with usage instructions
 */

(function () {
  'use strict';

  const STORAGE_KEY = `uiforge:${window.UIFORGE_SCREEN_ID || 'unknown'}:pins`;
  const SCENARIO_KEY = `uiforge:${window.UIFORGE_SCREEN_ID || 'unknown'}:scenario`;
  const FILTER_KEY = `uiforge:${window.UIFORGE_SCREEN_ID || 'unknown'}:round-filter`;
  const ROUNDS_KEY = STORAGE_KEY + ':rounds';
  const IS_SERVED = location.protocol.startsWith('http');

  const PIN_TYPES = {
    change: { color: '#3b82f6', label: 'Cambio' },
    'extract-as-component': { color: '#10b981', label: 'Extraer como componente' },
    'replace-with-registry': { color: '#8b5cf6', label: 'Usar de cat\u00E1logo' },
    'token-issue': { color: '#f59e0b', label: 'Problema de token' },
    'data-issue': { color: '#ef4444', label: 'Problema de datos' },
  };

  let pins = [];
  let currentScenario = 'happy';
  let pinIdCounter = 1;
  let annotating = false;
  let panelOpen = false;
  let roundFilter = 'pending';

  let dragging = false;
  let dragStart = null;
  let dragRect = null;
  let dragOccurred = false;

  let hoverTarget = null;
  let refineActive = false;
  let refineTarget = null;
  let refineStack = [];

  function loadState() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const parsed = JSON.parse(raw);
        pins = (parsed.pins || []).map((p) => ({
          ...p,
          sentInRound: p.sentInRound ?? null,
        }));
        pinIdCounter = (pins.reduce((m, p) => Math.max(m, p.id), 0) || 0) + 1;
      }
      currentScenario = localStorage.getItem(SCENARIO_KEY) || 'happy';
      roundFilter = localStorage.getItem(FILTER_KEY) || 'pending';
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
      #uiforge-pins-list li.sent { opacity: .5; }
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
      .uiforge-pin.sent { opacity: .35; }
      .uiforge-region {
        position: absolute; border: 2px dashed; border-radius: 4px;
        background: rgba(59, 130, 246, .08); cursor: pointer;
        z-index: 999996; box-sizing: border-box;
      }
      .uiforge-region.sent { opacity: .35; }
      .uiforge-region-badge {
        position: absolute; top: -12px; left: -12px;
        width: 24px; height: 24px; border-radius: 50%;
        color: white; font-weight: bold; font-size: 12px;
        display: flex; align-items: center; justify-content: center;
        border: 2px solid white; box-shadow: 0 2px 6px rgba(0,0,0,.4);
      }
      #uiforge-drag-rect {
        position: absolute; border: 2px dashed #3b82f6;
        background: rgba(59, 130, 246, .12); z-index: 999999;
        pointer-events: none; box-sizing: border-box;
      }
      body.uiforge-annotating { cursor: crosshair !important; }
      body.uiforge-annotating #uiforge-root * { cursor: crosshair !important; }
      #uiforge-modal {
        position: fixed; inset: 0; z-index: 1000000;
        background: rgba(15, 23, 42, .72);
        -webkit-backdrop-filter: blur(3px); backdrop-filter: blur(3px);
        display: flex; align-items: center; justify-content: center;
        font-family: ui-sans-serif, system-ui, sans-serif;
        animation: uiforge-fade .12s ease-out;
      }
      @keyframes uiforge-fade { from { opacity: 0 } to { opacity: 1 } }
      #uiforge-modal .modal-box {
        background: #0f172a; color: #e2e8f0;
        width: 480px; max-width: 92vw; max-height: 92vh;
        border-radius: 10px; box-shadow: 0 24px 48px rgba(0,0,0,.55);
        padding: 20px; box-sizing: border-box;
        border: 1px solid #334155;
        display: flex; flex-direction: column; gap: 14px;
      }
      #uiforge-modal .modal-header {
        display: flex; justify-content: space-between; align-items: center;
      }
      #uiforge-modal h3 { margin: 0; font-size: 15px; font-weight: 600; }
      #uiforge-modal .modal-close {
        background: transparent; color: #94a3b8; border: none;
        font-size: 22px; cursor: pointer; padding: 0 4px; line-height: 1;
      }
      #uiforge-modal .modal-close:hover { color: #e2e8f0; }
      #uiforge-modal label {
        display: block; font-size: 10px; color: #94a3b8;
        margin-bottom: 6px; text-transform: uppercase;
        letter-spacing: .6px; font-weight: 600;
      }
      #uiforge-modal textarea {
        width: 100%; min-height: 96px; box-sizing: border-box;
        background: #1e293b; border: 1px solid #334155; border-radius: 6px;
        color: #e2e8f0; font-family: inherit; font-size: 13px;
        padding: 10px; resize: vertical; outline: none;
        transition: border-color .15s ease;
      }
      #uiforge-modal textarea:focus { border-color: #3b82f6; }
      #uiforge-modal .type-chips {
        display: flex; flex-wrap: wrap; gap: 6px;
      }
      #uiforge-modal .type-chip {
        background: transparent; color: #cbd5e1;
        border: 1.5px solid var(--chip-color, #3b82f6);
        padding: 6px 12px; border-radius: 9999px;
        cursor: pointer; font-size: 12px; font-weight: 500;
        transition: all .12s ease;
      }
      #uiforge-modal .type-chip:hover {
        background: color-mix(in srgb, var(--chip-color, #3b82f6) 18%, transparent);
      }
      #uiforge-modal .type-chip.selected {
        background: var(--chip-color, #3b82f6); color: white;
      }
      #uiforge-modal .hint {
        font-size: 11px; color: #64748b; text-align: right;
        margin-top: -6px;
      }
      #uiforge-modal .modal-actions {
        display: flex; justify-content: flex-end; gap: 8px; margin-top: 2px;
      }
      #uiforge-modal .modal-actions button {
        background: #1e293b; color: #e2e8f0;
        border: 1px solid #334155; padding: 8px 16px;
        border-radius: 6px; cursor: pointer; font-size: 13px;
        font-weight: 500; transition: background .15s ease;
      }
      #uiforge-modal .modal-actions button:hover:not(:disabled) { background: #334155; }
      #uiforge-modal .modal-actions button:disabled { opacity: .4; cursor: not-allowed; }
      #uiforge-modal .modal-actions button.primary {
        background: #3b82f6; border-color: #3b82f6;
      }
      #uiforge-modal .modal-actions button.primary:hover:not(:disabled) { background: #2563eb; }
      .uiforge-hover-outline {
        outline: 2px dashed rgba(59, 130, 246, .7) !important;
        outline-offset: 2px !important;
      }
      .uiforge-refine-outline {
        outline: 3px solid #10b981 !important;
        outline-offset: 2px !important;
        box-shadow: 0 0 0 6px rgba(16, 185, 129, .18) !important;
      }
      #uiforge-hud {
        position: fixed; top: 16px; left: 50%; transform: translateX(-50%);
        background: #0f172a; color: #e2e8f0;
        font-family: ui-sans-serif, system-ui, sans-serif;
        font-size: 12px; padding: 10px 14px; border-radius: 8px;
        border: 1px solid #334155;
        box-shadow: 0 8px 24px rgba(0,0,0,.45);
        z-index: 1000001; max-width: 80vw; pointer-events: none;
        animation: uiforge-fade .12s ease-out;
      }
      #uiforge-hud .breadcrumb {
        font-family: ui-monospace, 'SF Mono', Menlo, Consolas, monospace;
        color: #cbd5e1; white-space: nowrap;
        overflow: hidden; text-overflow: ellipsis;
        direction: rtl; text-align: left;
        max-width: 70vw;
      }
      #uiforge-hud .breadcrumb .current {
        color: #10b981; font-weight: 700;
      }
      #uiforge-hud .breadcrumb .sep { color: #64748b; }
      #uiforge-hud .keys { margin-top: 6px; font-size: 11px; color: #94a3b8; }
      #uiforge-hud kbd {
        display: inline-block; padding: 1px 5px; border-radius: 3px;
        background: #1e293b; border: 1px solid #334155;
        font-family: ui-monospace, monospace; font-size: 10px;
        margin: 0 2px; color: #e2e8f0;
      }
      #uiforge-toast {
        position: fixed; bottom: 88px; right: 20px;
        background: #0f172a; color: #e2e8f0;
        border: 1px solid #334155; border-radius: 8px;
        padding: 10px 14px;
        font-family: ui-sans-serif, system-ui, sans-serif;
        font-size: 13px; font-weight: 500;
        box-shadow: 0 8px 24px rgba(0,0,0,.45);
        z-index: 1000002; max-width: 320px;
        display: flex; align-items: center; gap: 10px;
        animation: uiforge-toast-in .2s ease-out;
        transition: opacity .2s ease, transform .2s ease;
      }
      #uiforge-toast.hiding { opacity: 0; transform: translateY(8px); }
      #uiforge-toast.success { border-color: #10b981; }
      #uiforge-toast.success .uiforge-toast-icon { color: #10b981; }
      #uiforge-toast.error { border-color: #ef4444; }
      #uiforge-toast.error .uiforge-toast-icon { color: #ef4444; }
      .uiforge-toast-spinner {
        width: 14px; height: 14px;
        border: 2px solid #334155; border-top-color: #3b82f6;
        border-radius: 50%;
        animation: uiforge-spin .8s linear infinite;
        flex-shrink: 0;
      }
      .uiforge-toast-icon {
        flex-shrink: 0; font-size: 16px; line-height: 1; font-weight: 700;
      }
      .uiforge-toast-msg { flex: 1; min-width: 0; line-height: 1.3; }
      .uiforge-toast-close {
        background: transparent; border: none; color: #94a3b8;
        cursor: pointer; font-size: 16px; padding: 0 2px; line-height: 1;
      }
      .uiforge-toast-close:hover { color: #e2e8f0; }
      @keyframes uiforge-spin { to { transform: rotate(360deg); } }
      @keyframes uiforge-toast-in {
        from { opacity: 0; transform: translateY(8px); }
        to { opacity: 1; transform: translateY(0); }
      }
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
      fab.innerHTML = '<span>\u{1F4CD}</span><span id="uiforge-fab-badge" class="hidden">0</span>';
      fab.addEventListener('click', togglePanel);
      document.body.appendChild(fab);
    }
    fab.classList.toggle('annotating', annotating);
    const badge = document.getElementById('uiforge-fab-badge');
    const pending = pins.filter((p) => !p.sentInRound).length;
    if (pins.length > 0) {
      badge.textContent = pending > 0 ? pending : pins.length;
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

  function getVisiblePins() {
    if (roundFilter === 'all') return pins;
    if (roundFilter === 'pending') return pins.filter((p) => !p.sentInRound);
    return pins.filter((p) => p.sentInRound === parseInt(roundFilter, 10));
  }

  function getSentRounds() {
    const rounds = [...new Set(pins.filter((p) => p.sentInRound).map((p) => p.sentInRound))];
    return rounds.sort((a, b) => a - b);
  }

  function renderPanel() {
    let panel = document.getElementById('uiforge-panel');
    if (!panel) {
      panel = document.createElement('div');
      panel.id = 'uiforge-panel';
      document.body.appendChild(panel);
    }
    const scenarios = window.UIFORGE_SCENARIOS || ['happy'];
    const sentRounds = getSentRounds();
    const pending = pins.filter((p) => !p.sentInRound).length;
    const visible = getVisiblePins();

    panel.innerHTML = ''
      + '<header>'
      + '<h2>ui-forge \u00B7 ' + escapeHtml(window.UIFORGE_SCREEN_ID || 'screen') + '</h2>'
      + '<button id="uiforge-close" title="Cerrar (P)">\u00D7</button>'
      + '</header>'
      + '<details style="margin-bottom:12px;font-size:11px;color:#94a3b8">'
      + '<summary style="cursor:pointer;font-weight:600;color:#e2e8f0">Leyenda</summary>'
      + '<div style="margin-top:6px;line-height:1.8">'
      + '<div>\u{1F4CC} <b>Click</b> \u2014 fija elemento y entra en refine</div>'
      + '<div>\u{1F532} <b>Shift+arrastrar</b> \u2014 \u00E1rea + refine desde ancestro com\u00FAn</div>'
      + '<div>\u2328\uFE0F <b>\u2191/\u2193</b> \u2014 en refine: padre / hijo previo</div>'
      + '<div>\u2328\uFE0F <b>Enter/Esc</b> \u2014 en refine: anotar / cancelar</div>'
      + '<div>\u2328\uFE0F <b>A</b> \u2014 toggle modo anotaci\u00F3n</div>'
      + '<div>\u2328\uFE0F <b>P</b> \u2014 toggle panel lateral</div>'
      + '<hr style="border-color:#334155;margin:6px 0">'
      + '<div style="display:flex;gap:8px;flex-wrap:wrap">'
      + Object.entries(PIN_TYPES).map(function(e) { return '<span style="color:' + e[1].color + '">\u25CF ' + e[1].label + '</span>'; }).join('')
      + '</div>'
      + '<hr style="border-color:#334155;margin:6px 0">'
      + '<div>\u25CF opaco = pendiente \u00B7 \u25CF tenue = enviado en ronda anterior</div>'
      + '</div></details>'
      + '<div><label style="font-size:11px;color:#94a3b8">Escenario</label>'
      + '<select id="uiforge-scenario">'
      + scenarios.map(function(s) { return '<option value="' + s + '"' + (s === currentScenario ? ' selected' : '') + '>' + s + '</option>'; }).join('')
      + '</select></div>'
      + '<div style="margin-top:8px"><label style="font-size:11px;color:#94a3b8">Ronda</label>'
      + '<select id="uiforge-round-filter">'
      + '<option value="all"' + (roundFilter === 'all' ? ' selected' : '') + '>Todos (' + pins.length + ')</option>'
      + '<option value="pending"' + (roundFilter === 'pending' ? ' selected' : '') + '>Pendientes (' + pending + ')</option>'
      + sentRounds.map(function(r) { return '<option value="' + r + '"' + (roundFilter === String(r) ? ' selected' : '') + '>Round ' + r + ' (' + pins.filter(function(p) { return p.sentInRound === r; }).length + ')</option>'; }).join('')
      + '</select></div>'
      + '<div class="row" style="margin-top:12px">'
      + '<button id="uiforge-toggle" class="' + (annotating ? 'danger' : 'primary') + '">'
      + (annotating ? 'Salir (A)' : 'Anotar (A)')
      + '</button>'
      + (IS_SERVED ? '<button id="uiforge-send" class="primary" title="Enviar feedback a Claude"' + (pending === 0 ? ' disabled' : '') + '>\u{1F680}</button>' : '')
      + '<button id="uiforge-copy" title="Copiar JSON al portapapeles"' + (pins.length === 0 ? ' disabled' : '') + '>\u{1F4CB}</button>'
      + '<button id="uiforge-download" title="Descargar JSON"' + (pins.length === 0 ? ' disabled' : '') + '>\u2B07</button>'
      + '<button id="uiforge-clear" class="danger"' + (pins.length === 0 ? ' disabled' : '') + '>Clear</button>'
      + '</div>'
      + '<div id="uiforge-meta">'
      + pins.length + ' pin' + (pins.length === 1 ? '' : 's') + ' total \u00B7 ' + pending + ' pendiente' + (pending === 1 ? '' : 's') + ' \u00B7 pr\u00F3xima ronda: ' + getNextRound()
      + '</div>';

    if (visible.length === 0) {
      panel.innerHTML += '<div id="uiforge-empty">Sin anotaciones visibles. Pulsa <b>A</b> y haz click (o Shift+arrastra) sobre la pantalla.</div>';
    } else {
      var listHtml = '<ul id="uiforge-pins-list">';
      visible.forEach(function(p) {
        var color = (PIN_TYPES[p.type] && PIN_TYPES[p.type].color) || '#3b82f6';
        var label = (PIN_TYPES[p.type] && PIN_TYPES[p.type].label) || p.type;
        listHtml += '<li style="border-left-color:' + color + '" class="' + (p.sentInRound ? 'sent' : '') + '">'
          + '<div class="pin-meta">'
          + '<span>#' + p.id + ' \u00B7 ' + (p.region ? '\u{1F532}' : '\u{1F4CC}') + ' \u00B7 ' + p.scenario + (p.sentInRound ? ' \u00B7 R' + p.sentInRound : '') + '</span>'
          + '<span style="color:' + color + '">' + label + '</span>'
          + '</div>'
          + '<textarea class="pin-comment" data-pin="' + p.id + '" rows="2">' + escapeHtml(p.comment) + '</textarea>'
          + '<div class="pin-actions">'
          + '<select data-pin-type="' + p.id + '" style="flex:1;font-size:11px">'
          + Object.entries(PIN_TYPES).map(function(e) { return '<option value="' + e[0] + '"' + (e[0] === p.type ? ' selected' : '') + '>' + e[1].label + '</option>'; }).join('')
          + '</select>'
          + '<button data-pin-goto="' + p.id + '" title="Ir al pin">\u2192</button>'
          + '<button data-pin-delete="' + p.id + '" class="danger" title="Borrar">\u00D7</button>'
          + '</div></li>';
      });
      listHtml += '</ul>';
      panel.innerHTML += listHtml;
    }

    document.getElementById('uiforge-close').addEventListener('click', togglePanel);
    document.getElementById('uiforge-scenario').addEventListener('change', function(e) {
      currentScenario = e.target.value;
      saveState();
      applyScenario();
    });
    document.getElementById('uiforge-round-filter').addEventListener('change', function(e) {
      roundFilter = e.target.value;
      try { localStorage.setItem(FILTER_KEY, roundFilter); } catch (err) { /* ignore */ }
      renderPins();
      renderPanel();
    });
    document.getElementById('uiforge-toggle').addEventListener('click', toggleAnnotating);
    var sendBtn = document.getElementById('uiforge-send');
    if (sendBtn && !sendBtn.disabled) sendBtn.addEventListener('click', sendToClaude);
    var copyBtn = document.getElementById('uiforge-copy');
    if (copyBtn && !copyBtn.disabled) copyBtn.addEventListener('click', exportToClipboard);
    var downloadBtn = document.getElementById('uiforge-download');
    if (downloadBtn && !downloadBtn.disabled) downloadBtn.addEventListener('click', exportToDownload);
    var clearBtn = document.getElementById('uiforge-clear');
    if (clearBtn && !clearBtn.disabled) {
      clearBtn.addEventListener('click', function() {
        if (confirm('Borrar las ' + pins.length + ' pins acumuladas?')) {
          pins = [];
          saveState();
          renderPins();
          renderPanel();
          renderFab();
        }
      });
    }
    panel.querySelectorAll('[data-pin]').forEach(function(ta) {
      ta.addEventListener('input', function(e) {
        var id = +e.target.dataset.pin;
        var p = pins.find(function(x) { return x.id === id; });
        if (p) { p.comment = e.target.value; saveState(); }
      });
    });
    panel.querySelectorAll('[data-pin-type]').forEach(function(sel) {
      sel.addEventListener('change', function(e) {
        var id = +e.target.dataset.pinType;
        var p = pins.find(function(x) { return x.id === id; });
        if (p) { p.type = e.target.value; saveState(); renderPins(); renderPanel(); }
      });
    });
    panel.querySelectorAll('[data-pin-goto]').forEach(function(btn) {
      btn.addEventListener('click', function(e) {
        var id = +e.target.dataset.pinGoto;
        var p = pins.find(function(x) { return x.id === id; });
        if (p) {
          var scrollY = p.region ? p.region.y : p.y;
          window.scrollTo({ top: scrollY - window.innerHeight / 2, behavior: 'smooth' });
          var sel = p.region
            ? '.uiforge-region[data-pin-id="' + p.id + '"]'
            : '.uiforge-pin[data-pin-id="' + p.id + '"]';
          var el = document.querySelector(sel);
          if (el) {
            el.style.transition = 'transform .3s';
            el.style.transform = p.region ? 'scale(1.05)' : 'translate(-50%, -50%) scale(1.8)';
            setTimeout(function() { el.style.transform = p.region ? '' : 'translate(-50%, -50%)'; }, 400);
          }
        }
      });
    });
    panel.querySelectorAll('[data-pin-delete]').forEach(function(btn) {
      btn.addEventListener('click', function(e) {
        var id = +e.target.dataset.pinDelete;
        pins = pins.filter(function(p) { return p.id !== id; });
        saveState();
        renderPins();
        renderPanel();
        renderFab();
      });
    });
  }

  function escapeHtml(s) {
    return (s || '').replace(/[&<>"']/g, function(c) {
      return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c];
    });
  }

  function renderPins() {
    document.querySelectorAll('.uiforge-pin, .uiforge-region').forEach(function(el) { el.remove(); });
    var visible = getVisiblePins();
    visible.forEach(function(p) {
      var isSent = p.sentInRound !== null;
      var color = (PIN_TYPES[p.type] && PIN_TYPES[p.type].color) || '#3b82f6';
      var title = ((PIN_TYPES[p.type] && PIN_TYPES[p.type].label) || p.type) + ': ' + p.comment;

      if (p.region) {
        var el = document.createElement('div');
        el.className = 'uiforge-region' + (isSent ? ' sent' : '');
        el.dataset.pinId = p.id;
        el.style.left = p.region.x + 'px';
        el.style.top = p.region.y + 'px';
        el.style.width = p.region.w + 'px';
        el.style.height = p.region.h + 'px';
        el.style.borderColor = color;
        el.title = title;
        var badge = document.createElement('span');
        badge.className = 'uiforge-region-badge';
        badge.style.background = color;
        badge.textContent = p.id;
        el.appendChild(badge);
        el.addEventListener('click', function(e) { e.stopPropagation(); if (!panelOpen) togglePanel(); });
        document.body.appendChild(el);
      } else {
        var el2 = document.createElement('div');
        el2.className = 'uiforge-pin' + (isSent ? ' sent' : '');
        el2.dataset.pinId = p.id;
        el2.style.left = p.x + 'px';
        el2.style.top = p.y + 'px';
        el2.style.background = color;
        el2.textContent = p.id;
        el2.title = title;
        el2.addEventListener('click', function(e) { e.stopPropagation(); if (!panelOpen) togglePanel(); });
        document.body.appendChild(el2);
      }
    });
  }

  function toggleAnnotating() {
    annotating = !annotating;
    document.body.classList.toggle('uiforge-annotating', annotating);
    if (!annotating) clearHover();
    renderFab();
    if (panelOpen) renderPanel();
  }

  function isOverlayElement(el) {
    return el.closest('#uiforge-panel') || el.closest('#uiforge-fab') ||
      el.closest('#uiforge-modal') || el.closest('#uiforge-hud') ||
      el.classList.contains('uiforge-pin') || el.classList.contains('uiforge-region') ||
      el.closest('.uiforge-region');
  }

  var toastHideTimer = null;

  function showToast(message, opts) {
    opts = opts || {};
    var state = opts.state || 'loading';
    var autoHideMs = opts.autoHideMs || null;
    var closable = opts.closable || false;

    var toast = document.getElementById('uiforge-toast');
    if (!toast) {
      toast = document.createElement('div');
      toast.id = 'uiforge-toast';
      document.body.appendChild(toast);
    }
    toast.classList.remove('success', 'error', 'hiding');
    if (state === 'success') toast.classList.add('success');
    if (state === 'error') toast.classList.add('error');
    toast.replaceChildren();

    if (state === 'loading') {
      var spinner = document.createElement('div');
      spinner.className = 'uiforge-toast-spinner';
      toast.appendChild(spinner);
    } else {
      var icon = document.createElement('span');
      icon.className = 'uiforge-toast-icon';
      icon.textContent = state === 'success' ? '\u2713' : '\u2717';
      toast.appendChild(icon);
    }

    var msg = document.createElement('div');
    msg.className = 'uiforge-toast-msg';
    msg.textContent = message;
    toast.appendChild(msg);

    if (closable) {
      var close = document.createElement('button');
      close.className = 'uiforge-toast-close';
      close.type = 'button';
      close.textContent = '\u00D7';
      close.addEventListener('click', hideToast);
      toast.appendChild(close);
    }

    if (toastHideTimer) { clearTimeout(toastHideTimer); toastHideTimer = null; }
    if (autoHideMs) {
      toastHideTimer = setTimeout(hideToast, autoHideMs);
    }
  }

  function hideToast() {
    if (toastHideTimer) { clearTimeout(toastHideTimer); toastHideTimer = null; }
    var toast = document.getElementById('uiforge-toast');
    if (!toast) return;
    toast.classList.add('hiding');
    setTimeout(function() {
      if (toast.parentElement) toast.remove();
    }, 200);
  }

  function showReloadSuccessIfPending() {
    try {
      var raw = sessionStorage.getItem('uiforge:reloadPending');
      sessionStorage.removeItem('uiforge:reloadPending');
      if (!raw) return;
      var parsed = JSON.parse(raw);
      var age = Date.now() - (parsed.t || 0);
      if (age > 60000) return;
      showToast('Round ' + parsed.round + ' aplicado', { state: 'success', autoHideMs: 2500 });
    } catch (e) { /* ignore */ }
  }

  function applyHover(el) {
    if (!el || el === hoverTarget) return;
    clearHover();
    hoverTarget = el;
    el.classList.add('uiforge-hover-outline');
  }

  function clearHover() {
    document.querySelectorAll('.uiforge-hover-outline').forEach(function(el) {
      el.classList.remove('uiforge-hover-outline');
    });
    hoverTarget = null;
  }

  function applyRefineOutline(el) {
    document.querySelectorAll('.uiforge-refine-outline').forEach(function(x) {
      x.classList.remove('uiforge-refine-outline');
    });
    if (el) el.classList.add('uiforge-refine-outline');
  }

  function clearRefineOutline() {
    document.querySelectorAll('.uiforge-refine-outline').forEach(function(x) {
      x.classList.remove('uiforge-refine-outline');
    });
  }

  function buildBreadcrumb(el) {
    var parts = [];
    var node = el;
    var isCurrent = true;
    while (node && node.tagName && node !== document.documentElement) {
      var seg = node.tagName.toLowerCase();
      if (node.id) {
        seg += '#' + node.id;
      } else if (typeof node.className === 'string' && node.className.trim()) {
        var first = node.className.split(/\s+/).filter(Boolean)[0];
        if (first) seg += '.' + first;
      }
      parts.unshift({ text: seg, current: isCurrent });
      isCurrent = false;
      node = node.parentElement;
    }
    return parts;
  }

  function renderHUD() {
    var hud = document.getElementById('uiforge-hud');
    if (!hud) {
      hud = document.createElement('div');
      hud.id = 'uiforge-hud';
      var bc = document.createElement('div');
      bc.className = 'breadcrumb';
      hud.appendChild(bc);
      var keys = document.createElement('div');
      keys.className = 'keys';
      var k1 = document.createElement('kbd'); k1.textContent = '\u2191';
      var k2 = document.createElement('kbd'); k2.textContent = '\u2193';
      var k3 = document.createElement('kbd'); k3.textContent = 'Enter';
      var k4 = document.createElement('kbd'); k4.textContent = 'Esc';
      keys.appendChild(k1);
      keys.appendChild(document.createTextNode(' padre \u00B7 '));
      keys.appendChild(k2);
      keys.appendChild(document.createTextNode(' hijo \u00B7 '));
      keys.appendChild(k3);
      keys.appendChild(document.createTextNode(' anotar \u00B7 '));
      keys.appendChild(k4);
      keys.appendChild(document.createTextNode(' cancelar'));
      hud.appendChild(keys);
      document.body.appendChild(hud);
    }
    updateHUDContent();
  }

  function updateHUDContent() {
    var hud = document.getElementById('uiforge-hud');
    if (!hud || !refineTarget) return;
    var bc = hud.querySelector('.breadcrumb');
    bc.replaceChildren();
    var parts = buildBreadcrumb(refineTarget);
    parts.forEach(function(p, i) {
      var span = document.createElement('span');
      span.textContent = p.text;
      if (p.current) span.className = 'current';
      bc.appendChild(span);
      if (i < parts.length - 1) {
        var sep = document.createElement('span');
        sep.className = 'sep';
        sep.textContent = ' \u203A ';
        bc.appendChild(sep);
      }
    });
  }

  function hideHUD() {
    var hud = document.getElementById('uiforge-hud');
    if (hud) hud.remove();
  }

  function captureSnapshot(el) {
    if (!el || !el.getBoundingClientRect) return null;
    var tag = (el.tagName || '').toLowerCase();
    var id = el.id || null;
    var classes = (typeof el.className === 'string')
      ? el.className.split(/\s+/).filter(Boolean)
      : [];
    var html = el.outerHTML || '';
    var HTML_MAX = 600;
    if (html.length > HTML_MAX) html = html.slice(0, HTML_MAX) + '\n\u2026[truncated]';
    var text = (el.textContent || '').trim().replace(/\s+/g, ' ');
    if (text.length > 200) text = text.slice(0, 200) + '\u2026';
    var r = el.getBoundingClientRect();
    return {
      tag: tag, id: id, classes: classes,
      html: html, text: text,
      bbox: {
        x: Math.round(r.left + window.scrollX),
        y: Math.round(r.top + window.scrollY),
        w: Math.round(r.width),
        h: Math.round(r.height),
      },
      path: getSelector(el),
    };
  }

  function deepestCommonAncestorInRegion(region) {
    var root = document.getElementById('uiforge-root') || document.body;
    var inside = [];
    root.querySelectorAll('*').forEach(function(el) {
      var r = el.getBoundingClientRect();
      if (r.width === 0 || r.height === 0) return;
      var absX = r.left + window.scrollX;
      var absY = r.top + window.scrollY;
      if (absX >= region.x && absY >= region.y &&
          absX + r.width <= region.x + region.w &&
          absY + r.height <= region.y + region.h) {
        inside.push(el);
      }
    });
    if (inside.length === 0) {
      var cx = region.x + region.w / 2 - window.scrollX;
      var cy = region.y + region.h / 2 - window.scrollY;
      return document.elementFromPoint(cx, cy) || root;
    }
    var candidate = inside[0];
    while (candidate && !inside.every(function(el) { return candidate.contains(el) || candidate === el; })) {
      candidate = candidate.parentElement;
    }
    return candidate || root;
  }

  function enterRefineMode(initialTarget) {
    return new Promise(function(resolve) {
      if (!initialTarget || !initialTarget.tagName) { resolve(null); return; }
      refineActive = true;
      refineTarget = initialTarget;
      refineStack = [];
      clearHover();
      applyRefineOutline(refineTarget);
      renderHUD();

      function finish(result) {
        document.removeEventListener('keydown', onKey, true);
        clearRefineOutline();
        hideHUD();
        refineActive = false;
        refineTarget = null;
        refineStack = [];
        resolve(result);
      }

      function onKey(e) {
        if (e.key === 'ArrowUp') {
          e.preventDefault(); e.stopPropagation();
          var parent = refineTarget.parentElement;
          if (parent && parent.tagName && parent !== document.documentElement && parent !== document.body.parentElement) {
            refineStack.push(refineTarget);
            refineTarget = parent;
            applyRefineOutline(refineTarget);
            updateHUDContent();
          }
        } else if (e.key === 'ArrowDown') {
          e.preventDefault(); e.stopPropagation();
          if (refineStack.length) {
            refineTarget = refineStack.pop();
            applyRefineOutline(refineTarget);
            updateHUDContent();
          }
        } else if (e.key === 'Enter') {
          e.preventDefault(); e.stopPropagation();
          finish(refineTarget);
        } else if (e.key === 'Escape') {
          e.preventDefault(); e.stopPropagation();
          finish(null);
        }
      }

      document.addEventListener('keydown', onKey, true);
    });
  }

  function promptPinDetails() {
    return new Promise(function(resolve) {
      var backdrop = document.createElement('div');
      backdrop.id = 'uiforge-modal';

      var box = document.createElement('div');
      box.className = 'modal-box';

      var header = document.createElement('div');
      header.className = 'modal-header';
      var title = document.createElement('h3');
      title.textContent = 'Nueva anotaci\u00F3n';
      var closeBtn = document.createElement('button');
      closeBtn.className = 'modal-close';
      closeBtn.type = 'button';
      closeBtn.textContent = '\u00D7';
      closeBtn.title = 'Cancelar (Esc)';
      header.appendChild(title);
      header.appendChild(closeBtn);

      var commentWrap = document.createElement('div');
      var commentLabel = document.createElement('label');
      commentLabel.textContent = 'Comentario';
      var textarea = document.createElement('textarea');
      textarea.placeholder = 'Describe el cambio, componente, token...';
      commentWrap.appendChild(commentLabel);
      commentWrap.appendChild(textarea);

      var typeWrap = document.createElement('div');
      var typeLabel = document.createElement('label');
      typeLabel.textContent = 'Tipo';
      var chips = document.createElement('div');
      chips.className = 'type-chips';
      var selectedType = 'change';
      Object.entries(PIN_TYPES).forEach(function(entry) {
        var key = entry[0];
        var spec = entry[1];
        var chip = document.createElement('button');
        chip.type = 'button';
        chip.className = 'type-chip' + (key === selectedType ? ' selected' : '');
        chip.textContent = spec.label;
        chip.style.setProperty('--chip-color', spec.color);
        chip.dataset.type = key;
        chip.addEventListener('click', function() {
          chips.querySelectorAll('.type-chip').forEach(function(c) { c.classList.remove('selected'); });
          chip.classList.add('selected');
          selectedType = key;
        });
        chips.appendChild(chip);
      });
      typeWrap.appendChild(typeLabel);
      typeWrap.appendChild(chips);

      var hint = document.createElement('div');
      hint.className = 'hint';
      hint.textContent = 'Esc para cancelar \u00B7 Cmd/Ctrl+Enter para guardar';

      var actions = document.createElement('div');
      actions.className = 'modal-actions';
      var cancelBtn = document.createElement('button');
      cancelBtn.type = 'button';
      cancelBtn.textContent = 'Cancelar';
      var saveBtn = document.createElement('button');
      saveBtn.type = 'button';
      saveBtn.className = 'primary';
      saveBtn.textContent = 'Guardar pin';
      saveBtn.disabled = true;
      actions.appendChild(cancelBtn);
      actions.appendChild(saveBtn);

      box.appendChild(header);
      box.appendChild(commentWrap);
      box.appendChild(typeWrap);
      box.appendChild(hint);
      box.appendChild(actions);
      backdrop.appendChild(box);
      document.body.appendChild(backdrop);

      function cleanup() {
        document.removeEventListener('keydown', onKey);
        backdrop.remove();
      }
      function cancel() { cleanup(); resolve(null); }
      function save() {
        var val = textarea.value.trim();
        if (!val) return;
        cleanup();
        resolve({ comment: val, type: selectedType });
      }
      function onKey(e) {
        if (e.key === 'Escape') { e.preventDefault(); cancel(); }
        if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) { e.preventDefault(); save(); }
      }

      closeBtn.addEventListener('click', cancel);
      cancelBtn.addEventListener('click', cancel);
      saveBtn.addEventListener('click', save);
      textarea.addEventListener('input', function() {
        saveBtn.disabled = !textarea.value.trim();
      });
      backdrop.addEventListener('click', function(e) {
        if (e.target === backdrop) cancel();
      });
      document.addEventListener('keydown', onKey);

      setTimeout(function() { textarea.focus(); }, 50);
    });
  }

  async function handleClick(e) {
    if (!annotating) return;
    if (dragOccurred) { dragOccurred = false; return; }
    if (e.shiftKey) return;
    if (refineActive) return;
    if (isOverlayElement(e.target)) return;
    e.preventDefault();
    e.stopPropagation();
    var initialTarget = e.target;
    var pageX = e.pageX;
    var pageY = e.pageY;
    clearHover();
    var refined = await enterRefineMode(initialTarget);
    if (!refined) return;
    var details = await promptPinDetails();
    if (!details) return;
    var pin = {
      id: pinIdCounter++,
      selector: getSelector(refined),
      x: pageX, y: pageY,
      region: null,
      snapshot: captureSnapshot(refined),
      viewport: { w: window.innerWidth, h: window.innerHeight },
      comment: details.comment, type: details.type, scenario: currentScenario,
      sentInRound: null,
      timestamp: new Date().toISOString(),
    };
    pins.push(pin);
    saveState();
    renderPins();
    renderFab();
    if (panelOpen) renderPanel();
  }

  function handleMouseDown(e) {
    if (!annotating || !e.shiftKey) return;
    if (isOverlayElement(e.target)) return;
    e.preventDefault();
    dragging = true;
    dragStart = { x: e.pageX, y: e.pageY };
    dragRect = document.createElement('div');
    dragRect.id = 'uiforge-drag-rect';
    dragRect.style.left = dragStart.x + 'px';
    dragRect.style.top = dragStart.y + 'px';
    dragRect.style.width = '0';
    dragRect.style.height = '0';
    document.body.appendChild(dragRect);
  }

  function handleMouseMove(e) {
    if (dragging && dragRect) {
      var x = Math.min(dragStart.x, e.pageX);
      var y = Math.min(dragStart.y, e.pageY);
      var w = Math.abs(e.pageX - dragStart.x);
      var h = Math.abs(e.pageY - dragStart.y);
      dragRect.style.left = x + 'px';
      dragRect.style.top = y + 'px';
      dragRect.style.width = w + 'px';
      dragRect.style.height = h + 'px';
      return;
    }
    if (annotating && !refineActive && !e.shiftKey) {
      if (e.target && !isOverlayElement(e.target)) {
        applyHover(e.target);
      } else {
        clearHover();
      }
    }
  }

  async function handleMouseUp(e) {
    if (!dragging) return;
    dragging = false;
    var w = Math.abs(e.pageX - dragStart.x);
    var h = Math.abs(e.pageY - dragStart.y);
    if (dragRect) dragRect.remove();
    dragRect = null;

    if (w < 10 && h < 10) {
      dragStart = null;
      return;
    }

    dragOccurred = true;
    var rx = Math.min(dragStart.x, e.pageX);
    var ry = Math.min(dragStart.y, e.pageY);
    dragStart = null;
    var region = { x: rx, y: ry, w: w, h: h };

    clearHover();
    var initialTarget = deepestCommonAncestorInRegion(region);
    var refined = await enterRefineMode(initialTarget);
    if (!refined) return;

    var details = await promptPinDetails();
    if (!details) return;

    var pin = {
      id: pinIdCounter++,
      selector: getSelector(refined),
      x: rx, y: ry,
      region: region,
      snapshot: captureSnapshot(refined),
      viewport: { w: window.innerWidth, h: window.innerHeight },
      comment: details.comment, type: details.type, scenario: currentScenario,
      sentInRound: null,
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
    var data = (window.UIFORGE_DATA || {})[currentScenario];
    if (!data) {
      console.warn('[ui-forge] escenario "' + currentScenario + '" no encontrado');
      return;
    }
    window.render(data);
    setTimeout(renderPins, 50);
  }

  function getNextRound() {
    return (parseInt(localStorage.getItem(ROUNDS_KEY), 10) || 0) + 1;
  }

  function buildPayload(round) {
    var newPins = pins.filter(function(p) { return !p.sentInRound; });
    return {
      screen: window.UIFORGE_SCREEN_ID,
      round: round,
      exportedAt: new Date().toISOString(),
      scenario: currentScenario,
      pinCount: pins.length,
      newPinCount: newPins.length,
      newPinIds: newPins.map(function(p) { return p.id; }),
      pins: pins,
    };
  }

  function bumpRound() {
    var round = getNextRound();
    localStorage.setItem(ROUNDS_KEY, String(round));
    return round;
  }

  function exportToClipboard() {
    if (!navigator.clipboard) {
      alert('Clipboard API no disponible. Usa el bot\u00F3n \u2B07 para descargar.');
      return;
    }
    var round = bumpRound();
    var json = JSON.stringify(buildPayload(round), null, 2);
    navigator.clipboard.writeText(json).then(
      function() {
        console.log('[ui-forge] JSON copiado');
        alert('round-' + String(round).padStart(2, '0') + ' copiado al portapapeles (' + pins.length + ' pins).');
      },
      function(err) {
        console.warn('[ui-forge] clipboard failed', err);
        alert('Fallo al copiar. Usa el bot\u00F3n \u2B07 para descargar.');
      }
    );
  }

  function exportToDownload() {
    var round = bumpRound();
    var json = JSON.stringify(buildPayload(round), null, 2);
    var blob = new Blob([json], { type: 'application/json' });
    var url = URL.createObjectURL(blob);
    var a = document.createElement('a');
    a.href = url;
    a.download = 'round-' + String(round).padStart(2, '0') + '.json';
    a.click();
    URL.revokeObjectURL(url);
    alert('Descargado round-' + String(round).padStart(2, '0') + '.json (' + pins.length + ' pins).');
  }

  function sendToClaude() {
    var round = bumpRound();
    var payload = buildPayload(round);
    var newCount = payload.newPinCount;
    showToast('Enviando round ' + round + ' (' + newCount + ' pin' + (newCount === 1 ? '' : 's') + ')\u2026', { state: 'loading' });
    fetch('/forge/feedback', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload, null, 2),
    })
      .then(function(r) {
        if (!r.ok) throw new Error('HTTP ' + r.status);
        return r.json();
      })
      .then(function() {
        pins.forEach(function(p) { if (!p.sentInRound) p.sentInRound = round; });
        saveState();
        renderPins();
        renderPanel();
        renderFab();
        try {
          sessionStorage.setItem('uiforge:reloadPending', JSON.stringify({ round: round, t: Date.now() }));
        } catch (e) { /* ignore */ }
        showToast('Round ' + round + ' enviado. Esperando cambios de Claude\u2026', { state: 'loading' });
      })
      .catch(function(err) {
        console.error('[ui-forge] send failed', err);
        showToast('Error enviando al servidor. Usa \u{1F4CB} como fallback.', { state: 'error', autoHideMs: 5000, closable: true });
      });
  }

  function setupSSE() {
    if (!IS_SERVED) return;
    var es = new EventSource('/forge/reload');
    es.addEventListener('reload', function() {
      console.log('[ui-forge] hot-reload triggered');
      showToast('Aplicando cambios\u2026', { state: 'loading' });
      setTimeout(function() { location.reload(); }, 250);
    });
    es.onerror = function() {
      console.warn('[ui-forge] SSE reconnecting...');
    };
  }

  function bindShortcuts() {
    document.addEventListener('keydown', function(e) {
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
    document.addEventListener('mousedown', handleMouseDown, true);
    document.addEventListener('mousemove', handleMouseMove, true);
    document.addEventListener('mouseup', handleMouseUp, true);
    window.addEventListener('resize', renderPins);
    bindShortcuts();
    applyScenario();
    renderPins();
    setupSSE();
    showReloadSuccessIfPending();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
