# Explore Checklist

Referencia completa de qué verificar durante una exploración proactiva.

## Descubrimiento de rutas

El agente debe descubrir las rutas del proyecto antes de explorar:

1. Leer la configuración del router (ej: `src/routes/`, `app/`, `pages/`)
2. Consultar CLAUDE.md o documentación del proyecto
3. Revisar el sitemap si existe
4. Explorar manualmente desde la navegación principal

Construir y mantener un inventario de rutas en el primer archivo de bitacora.

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
- [ ] Contenido no se desborda del viewport
- [ ] No hay texto cortado o truncado inesperadamente
- [ ] Tablas con scroll horizontal funcionan correctamente
- [ ] Cards y grids se alinean correctamente
- [ ] Responsive: verificar en viewport 1280px (desktop) y 375px (mobile)

### 4. Interacciones
- [ ] Botones responden al click (no quedan deshabilitados sin razón)
- [ ] Formularios muestran errores de validación
- [ ] Selects/dropdowns abren y cierran correctamente
- [ ] Modales/dialogs se abren y cierran (incluido click fuera)
- [ ] Popovers se posicionan correctamente
- [ ] Tooltips se muestran correctamente

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
- [ ] Campos requeridos están marcados
- [ ] Validación client-side funciona
- [ ] Submit muestra feedback (loading → success/error)
- [ ] Errores del servidor se muestran al usuario
- [ ] Formularios de edición cargan datos existentes

### 8. Accesibilidad básica
- [ ] Contraste de texto suficiente (especialmente en dark mode)
- [ ] Focus visible en inputs y botones (tab navigation)
- [ ] Imágenes con alt text
- [ ] Botones con aria-label cuando solo son iconos

### 9. Edición inline
- [ ] Click en campo editable → aparece input con valor actual
- [ ] Enter guarda, Escape cancela
- [ ] Blur (click fuera) guarda o cancela según el componente
- [ ] Icono lápiz visible en hover, oculto sin hover
- [ ] Tras guardar, el valor se actualiza sin recargar página
- [ ] Error de validación se muestra inline

### 10. Edge cases numéricos y texto
- [ ] Valores muy grandes (>1M) no desbordan columnas de tabla
- [ ] Valores negativos muestran signo y color rojo
- [ ] Valores cero se muestran correctamente (no como vacío)
- [ ] Nombres/textos muy largos se truncan correctamente
- [ ] Notas largas no rompen layout de tablas

### 11. Gráficos y visualizaciones
- [ ] Charts renderizan (no quedan en skeleton/spinner infinito)
- [ ] Tooltips de gráficos aparecen al hover
- [ ] Ejes muestran valores formateados
- [ ] Gráficos con datos vacíos muestran estado empty, no chart roto
- [ ] Charts se adaptan al ancho del contenedor

### 12. Recuperación de errores
- [ ] Tras un error de red/500, la app sigue funcional (no se queda bloqueada)
- [ ] Reintentar una acción fallida funciona
- [ ] ErrorBoundary se muestra en rutas con error, no pantalla blanca
- [ ] Toast/snackbar de error es dismissable

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

---

## Categorías específicas del proyecto

> Añade aquí checks específicos de tu proyecto. Ejemplos:
>
> - **Coherencia de datos cross-page**: Verificar que totales/contadores coinciden entre vistas
> - **Coherencia de componentes**: Verificar que badges, cards, formatos de fecha/número son consistentes
> - **i18n**: Buscar claves sin traducir, verificar en todos los idiomas
> - **Dark mode**: Verificar contraste, bordes, gráficos en ambos temas

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

  // Cleanup
  await context.close()

  // Return findings
  console.log(JSON.stringify({
    route: '{route}',
    consoleErrors: errors,
    hasOverflow: body.overflow,
    interactiveElements: { buttons, links }
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
