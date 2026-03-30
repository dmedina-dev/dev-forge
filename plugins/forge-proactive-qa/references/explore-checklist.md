# Explore Checklist

Referencia completa de qué verificar durante una exploración proactiva.

## Inventario de rutas

El inventario se genera con `/proactive-qa init` y se almacena en `{BITACORA_DIR}/route-inventory.md`. Contiene todas las rutas clasificadas por tipo (pública, autenticada, admin).

Si el inventario no existe, instruir al usuario a ejecutar `/proactive-qa init` antes de explorar.

## Checklist por página

Para cada ruta visitada, verificar:

### 1. Carga básica
- [ ] La página no muestra pantalla blanca
- [ ] No hay spinners infinitos (> 5 segundos)
- [ ] El título del documento es correcto
- [ ] El breadcrumb / header refleja la sección

### 2. Consola del navegador
- [ ] Sin errores en console (excepto warnings conocidos)
- [ ] Sin errores de red (4xx, 5xx) — salvo 401 esperados
- [ ] Sin errores de React/framework (hydration mismatch, key warnings)

### 3. Layout y maquetación
- [ ] Sidebar/nav visible y funcional
- [ ] Contenido no se desborda del viewport (sin scroll horizontal)
- [ ] No hay texto cortado o truncado inesperadamente
- [ ] Tablas con scroll horizontal funcionan correctamente
- [ ] Cards y grids se alinean correctamente
- [ ] Responsive: verificar en 375px, 768px, 1024px y 1440px
- [ ] Contenido no queda oculto detrás de navbars fijos
- [ ] Espacio reservado para contenido async (no layout shift al cargar)

### 4. Interacciones y estados
- [ ] Botones responden al click (no quedan deshabilitados sin razón)
- [ ] Todos los elementos clickables tienen `cursor: pointer`
- [ ] **Focus visible**: ring de 2px en todos los elementos interactivos (tab navigation)
- [ ] **Hover**: feedback visual claro (color, sombra, borde)
- [ ] **Active**: cambio visual al presionar (ej: scale-95)
- [ ] **Disabled**: opacidad reducida (~50%) + cursor `not-allowed`
- [ ] **Loading**: spinner o skeleton durante operaciones async; botón deshabilitado
- [ ] Selects/dropdowns abren y cierran correctamente
- [ ] Modales/dialogs se abren y cierran (incluido click fuera)
- [ ] Popovers se posicionan correctamente (no cortados por viewport)
- [ ] Tooltips se muestran correctamente
- [ ] Acciones destructivas requieren confirmación (dialog)

### 5. Datos
- [ ] Tablas muestran datos (no "Sin resultados" cuando debería haber data)
- [ ] Paginación funciona (siguiente, anterior, cambio de pageSize)
- [ ] Filtros filtran correctamente
- [ ] Ordenamiento funciona
- [ ] Estados vacíos se muestran cuando no hay datos

### 6. Navegación
- [ ] Links internos no producen 404
- [ ] Breadcrumbs llevan a la ruta correcta
- [ ] Botón "Volver" funciona
- [ ] Nav highlights la sección activa

### 7. Formularios
- [ ] Campos requeridos están marcados visualmente
- [ ] Todos los inputs tienen `<label>` asociado (no solo placeholder)
- [ ] Validación client-side funciona (inline, junto al campo)
- [ ] Submit muestra feedback (loading → success/error)
- [ ] Errores del servidor se muestran al usuario cerca del campo problemático
- [ ] Mensajes de error usan `aria-live="polite"` para screen readers
- [ ] Formularios de edición cargan datos existentes
- [ ] Inputs de tipo correcto (`email`, `tel`, `number`) para teclado móvil adecuado

### 8. Accesibilidad (WCAG AA)
- [ ] Contraste de texto mínimo 4.5:1 (normal) y 3:1 (large text)
- [ ] El color NO es el único indicador de estado (ej: error solo rojo sin icono/texto)
- [ ] Imágenes significativas con alt text descriptivo; decorativas con `aria-hidden="true"`
- [ ] Botones de solo icono tienen `aria-label`
- [ ] Jerarquía de headings correcta (h1 → h2 → h3, sin saltos)
- [ ] HTML semántico: `<button>` no `<div onClick>`, `<nav>`, `<main>`, `<article>`
- [ ] Tab order sigue el orden visual lógico
- [ ] Toda funcionalidad accesible por teclado (Enter, Space, Escape, Tab)
- [ ] Skip-to-main-content link para navegación por teclado
- [ ] `prefers-reduced-motion` respetado (animaciones deshabilitadas o reducidas)
- [ ] Viewport meta NO tiene `maximum-scale=1` (no deshabilitar zoom)

### 9. Edición inline
- [ ] Click en campo editable → aparece input con valor actual
- [ ] Enter guarda, Escape cancela
- [ ] Blur (click fuera) guarda o cancela según el componente
- [ ] Icono lápiz visible en hover, oculto sin hover
- [ ] Tras guardar, el valor se actualiza sin recargar página
- [ ] Error de validación se muestra inline

### 10. Tipografía y contenido
- [ ] Tamaño mínimo de texto body: 16px en mobile
- [ ] Longitud de línea legible: 65-75 caracteres máximo (usar `max-w-prose` o similar)
- [ ] Line-height adecuado: 1.5-1.75 para body text
- [ ] Formato de fechas consistente en toda la app
- [ ] Formato de números consistente (separador decimal, miles, moneda)
- [ ] Valores muy grandes (>1M) no desbordan columnas de tabla
- [ ] Valores negativos muestran signo y color diferenciado
- [ ] Valores cero se muestran correctamente (no como vacío)
- [ ] Nombres/textos muy largos se truncan correctamente (`text-overflow: ellipsis`)
- [ ] Placeholder content no aparece en producción (no "Lorem ipsum")

### 11. Gráficos y visualizaciones
- [ ] Charts renderizan (no quedan en skeleton/spinner infinito)
- [ ] Tooltips de gráficos aparecen al hover
- [ ] Ejes muestran valores formateados
- [ ] Gráficos con datos vacíos muestran estado empty, no chart roto
- [ ] Charts se adaptan al ancho del contenedor (ResponsiveContainer o equivalente)
- [ ] Colores de gráficos distinguibles para daltonismo (no solo rojo-verde)
- [ ] Gráficos adaptan colores al tema (dark/light)
- [ ] Tabla de datos alternativa disponible para accesibilidad

### 12. Recuperación de errores y feedback
- [ ] Tras un error de red/500, la app sigue funcional (no se queda bloqueada)
- [ ] Reintentar una acción fallida funciona
- [ ] ErrorBoundary se muestra en rutas con error, no pantalla blanca
- [ ] Toast/snackbar de error es dismissable
- [ ] Loading indicators para operaciones >300ms (skeleton o spinner)
- [ ] Indicadores de progreso para operaciones largas (upload, import)
- [ ] Confirmación visual tras acciones exitosas (toast success)

### 13. Persistencia de estado en URL
- [ ] Filtros de búsqueda persisten en URL params (recargar mantiene el filtro)
- [ ] Paginación persiste en URL
- [ ] Selecciones de periodo/filtro persisten en URL

### 14. Flujos multi-paso
- [ ] Cada paso navega correctamente (avance y retroceso)
- [ ] Estado se preserva entre pasos
- [ ] Cancelar en medio no deja datos corruptos

### 15. Protección contra duplicados
- [ ] Click rápido en submit no crea operaciones duplicadas (botón disabled durante submit)
- [ ] Double-click en acciones destructivas no duplica la acción
- [ ] Estado submitting deshabilita botones correctamente

### 16. Touch targets (mobile)
- [ ] Elementos interactivos mínimo 44x44px en mobile
- [ ] Mínimo 8px de separación entre targets táctiles adyacentes
- [ ] `touch-action: manipulation` para evitar delay de 300ms
- [ ] Hover-only no oculta funcionalidad esencial (en touch no hay hover)
- [ ] Gestos (swipe, pinch) no interfieren con scroll nativo

### 17. Dark mode / Light mode
- [ ] Texto legible en ambos modos (contraste mínimo 4.5:1)
- [ ] Bordes de cards/inputs visibles en ambos modos
- [ ] Elementos glass/transparentes visibles en light mode (`bg-white/80` mínimo)
- [ ] Gráficos adaptan colores (grid, ticks, tooltips) al tema
- [ ] Badges y pills con contraste suficiente en ambos modos
- [ ] Popovers y dropdowns con fondo correcto (bg-popover, no transparente)
- [ ] Imágenes/logos adaptan o tienen borde para separación del fondo

### 18. Performance visual
- [ ] Animaciones usan `transform` y `opacity` (GPU-accelerated), no `width`/`height`/`top`/`left`
- [ ] Duración de micro-interacciones: 150-300ms (no >500ms para UI)
- [ ] Easing correcto: `ease-out` entrada, `ease-in` salida (no `linear`)
- [ ] Hover effects NO causan layout shift (no cambio de tamaño/posición)
- [ ] Imágenes below-the-fold tienen `loading="lazy"`
- [ ] Imágenes con dimensiones explícitas (previenen Cumulative Layout Shift)
- [ ] No hay animaciones infinitas excepto loaders
- [ ] Máximo 1-2 elementos animados simultáneamente por vista

### 19. Consistencia de componentes
- [ ] Iconos del mismo set (no mezclar Heroicons con FontAwesome, etc.)
- [ ] No se usan emojis como sustituto de iconos SVG
- [ ] Badges/tags usan mismos colores y variantes en toda la app
- [ ] Cards de métricas usan el mismo patrón (label + valor + cambio)
- [ ] Selects usan el mismo componente (no mezclar custom con `<select>` nativo)
- [ ] Labels de formularios con tamaño y estilo consistente
- [ ] Estados vacíos usan el mismo patrón (no diseños ad-hoc por página)

---

## Categorías específicas del proyecto

> Añade aquí checks específicos de tu dominio. Ejemplos:
>
> - **Coherencia de datos cross-page**: Verificar que totales/contadores coinciden entre vistas
> - **i18n**: Buscar claves sin traducir (`ns:key.path`), verificar en todos los idiomas
> - **Permisos/roles**: Verificar que usuarios sin permisos no ven secciones restringidas
> - **Reglas de negocio**: Verificar cálculos específicos del dominio (totales, porcentajes, fórmulas)

---

## Playwright Script Template

Usar este patrón para explorar una ruta:

```typescript
import { test, expect } from '@playwright/test'

test('explore: {route}', async ({ browser }) => {
  // Use authenticated context
  const context = await browser.newContext({
    storageState: '{AUTH_STATE}'
  })
  const page = await context.newPage()

  // Collect console errors
  const errors: string[] = []
  page.on('console', msg => {
    if (msg.type() === 'error') errors.push(msg.text())
  })
  page.on('pageerror', err => {
    errors.push(err.message)
  })

  // Navigate
  await page.goto('{FRONTEND_URL}/{route}')
  await page.waitForLoadState('networkidle')

  // Screenshot
  await page.screenshot({
    path: process.env.TMPDIR + '/screenshot-{route}.png',
    fullPage: true
  })

  // Check layout
  const body = await page.evaluate(() => {
    const el = document.body
    return {
      scrollWidth: el.scrollWidth,
      clientWidth: el.clientWidth,
      overflow: el.scrollWidth > el.clientWidth
    }
  })

  // Check mobile viewport
  await page.setViewportSize({ width: 375, height: 812 })
  await page.screenshot({
    path: process.env.TMPDIR + '/screenshot-{route}-mobile.png',
    fullPage: true
  })

  // Check interactive elements
  const buttons = await page.locator('button:visible').count()
  const links = await page.locator('a:visible').count()

  // Check touch targets (44x44px minimum)
  const smallTargets = await page.evaluate(() => {
    const interactives = document.querySelectorAll('button, a, input, select, [role="button"]')
    const small: string[] = []
    interactives.forEach(el => {
      const rect = el.getBoundingClientRect()
      if (rect.width > 0 && rect.height > 0 && (rect.width < 44 || rect.height < 44)) {
        small.push(`${el.tagName}(${Math.round(rect.width)}x${Math.round(rect.height)})`)
      }
    })
    return small.slice(0, 10) // top 10
  })

  // Check accessibility basics
  const a11y = await page.evaluate(() => {
    const iconButtons = [...document.querySelectorAll('button')]
      .filter(b => !b.textContent?.trim() && !b.getAttribute('aria-label'))
    const imgsNoAlt = [...document.querySelectorAll('img')]
      .filter(i => !i.getAttribute('alt') && !i.getAttribute('aria-hidden'))
    const inputsNoLabel = [...document.querySelectorAll('input:not([type="hidden"])')]
      .filter(i => !i.getAttribute('aria-label') && !document.querySelector(`label[for="${i.id}"]`))
    return {
      iconButtonsNoLabel: iconButtons.length,
      imagesNoAlt: imgsNoAlt.length,
      inputsNoLabel: inputsNoLabel.length
    }
  })

  // Cleanup
  await context.close()

  // Return findings
  console.log(JSON.stringify({
    route: '{route}',
    consoleErrors: errors,
    hasOverflow: body.overflow,
    interactiveElements: { buttons, links },
    smallTouchTargets: smallTargets,
    a11yIssues: a11y
  }))
})
```

## Estrategia de cobertura

Para evitar repetir exploraciones, el agente explore debe:

1. Leer todos los ficheros en `{BITACORA_DIR}` al inicio
2. Extraer las rutas de la tabla "Rutas exploradas"
3. Calcular qué rutas del inventario NO han sido exploradas
4. Explorar las no cubiertas primero
5. Si todas están cubiertas, re-explorar las más antiguas (>7 días) para regresiones
6. Registrar SIEMPRE todas las rutas visitadas en la sesión actual

## Tipos de problema

| Tipo | Descripción | Ejemplo |
|------|-------------|---------|
| `funcionamiento` | Error funcional, algo no funciona | Botón submit no responde, 500 error |
| `maquetación` | Problema visual/CSS | Texto cortado, overflow, z-index incorrecto |
| `usabilidad` | UX confusa o mejorable | Feedback ausente, flujo poco claro |
| `rendimiento` | Lentitud notable | Página tarda >3s en cargar, lag en scroll |
| `accesibilidad` | Problema de a11y | Sin focus visible, contraste insuficiente |
| `consola` | Error en consola del navegador | React error, 404 de recurso |

## Severidad

| Nivel | Criterio |
|-------|----------|
| `critica` | La app crashea, datos se pierden, bloqueante |
| `alta` | Feature principal no funciona correctamente |
| `media` | Problema visible pero tiene workaround |
| `baja` | Cosmético o edge case poco frecuente |
