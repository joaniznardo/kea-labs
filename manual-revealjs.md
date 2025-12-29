# Manual de Reveal.js

Guia per crear presentacions HTML amb Reveal.js.

## Estructura Bàsica

```html
<!DOCTYPE html>
<html lang="ca">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Títol de la Presentació</title>

    <!-- CSS de Reveal.js des de CDN -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/reveal.js@4.6.0/dist/reset.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/reveal.js@4.6.0/dist/reveal.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/reveal.js@4.6.0/dist/theme/night.css">

    <!-- Plugin de ressaltat de codi -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/reveal.js@4.6.0/plugin/highlight/monokai.css">

    <style>
        /* Estils personalitzats */
        .reveal h1, .reveal h2, .reveal h3 { text-transform: none; }
        .reveal pre { width: 100%; font-size: 0.45em; }
    </style>
</head>
<body>
    <div class="reveal">
        <div class="slides">
            <!-- Diapositives aquí -->
        </div>
    </div>

    <!-- JavaScript de Reveal.js -->
    <script src="https://cdn.jsdelivr.net/npm/reveal.js@4.6.0/dist/reveal.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/reveal.js@4.6.0/plugin/highlight/highlight.js"></script>
    <script>
        Reveal.initialize({
            hash: true,
            slideNumber: true,
            plugins: [ RevealHighlight ]
        });
    </script>
</body>
</html>
```

## Diapositives

### Diapositiva Simple

```html
<section>
    <h2>Títol</h2>
    <p>Contingut de la diapositiva</p>
</section>
```

### Diapositives Verticals (Subseccions)

```html
<section>
    <!-- Diapositiva principal -->
    <section>
        <h2>Tema Principal</h2>
    </section>

    <!-- Diapositives verticals (navegar amb fletxa avall) -->
    <section>
        <h3>Subtema 1</h3>
    </section>

    <section>
        <h3>Subtema 2</h3>
    </section>
</section>
```

## Codi Font

### Bloc de Codi

```html
<pre><code class="yaml">
# Exemple de configuració YAML
server:
  host: localhost
  port: 8080
</code></pre>
```

### Llenguatges Suportats

- `yaml`, `json`, `bash`, `python`, `javascript`, `html`, `css`, `sql`, etc.
- Utilitza el nom del llenguatge a l'atribut `class`

### Codi Més Petit

```html
<section class="small-code">
    <pre><code class="bash">docker ps</code></pre>
</section>
```

CSS necessari:
```css
.reveal .small-code pre { font-size: 0.4em; }
.reveal .tiny-code pre { font-size: 0.35em; }
```

## Llistes

### Llista Desordenada

```html
<ul>
    <li>Element 1</li>
    <li>Element 2</li>
    <li>Element 3</li>
</ul>
```

### Llista Ordenada

```html
<ol>
    <li>Primer pas</li>
    <li>Segon pas</li>
    <li>Tercer pas</li>
</ol>
```

### Fragments (Apareixen un a un)

```html
<ul>
    <li class="fragment">Apareix primer</li>
    <li class="fragment">Apareix segon</li>
    <li class="fragment">Apareix tercer</li>
</ul>
```

## Taules

```html
<table>
    <thead>
        <tr>
            <th>Columna 1</th>
            <th>Columna 2</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>Dada 1</td>
            <td>Dada 2</td>
        </tr>
    </tbody>
</table>
```

## Layouts

### Dues Columnes

```html
<div class="columns">
    <div class="column">
        <h4>Columna Esquerra</h4>
        <p>Contingut</p>
    </div>
    <div class="column">
        <h4>Columna Dreta</h4>
        <p>Contingut</p>
    </div>
</div>
```

CSS necessari:
```css
.reveal .columns { display: flex; gap: 20px; }
.reveal .column { flex: 1; }
```

## Diagrames SVG

### SVG Inline

```html
<div class="diagram">
    <svg viewBox="0 0 400 200" style="width: 100%; max-width: 500px;">
        <!-- Rectangle -->
        <rect x="50" y="50" width="100" height="60" fill="#3498db" rx="5"/>

        <!-- Text -->
        <text x="100" y="85" text-anchor="middle" fill="white" font-size="12">
            Servidor
        </text>

        <!-- Línia -->
        <line x1="150" y1="80" x2="200" y2="80" stroke="#ecf0f1" stroke-width="2"/>

        <!-- Cercle -->
        <circle cx="250" cy="80" r="30" fill="#e74c3c"/>
    </svg>
</div>
```

CSS recomanat:
```css
.reveal .diagram { background: #1a1a2e; padding: 20px; border-radius: 10px; }
```

### Elements SVG Comuns

| Element | Descripció | Exemple |
|---------|------------|---------|
| `<rect>` | Rectangle | `<rect x="0" y="0" width="100" height="50" fill="#color" rx="5"/>` |
| `<circle>` | Cercle | `<circle cx="50" cy="50" r="25" fill="#color"/>` |
| `<line>` | Línia | `<line x1="0" y1="0" x2="100" y2="0" stroke="#color" stroke-width="2"/>` |
| `<text>` | Text | `<text x="50" y="50" text-anchor="middle" fill="white">Text</text>` |
| `<path>` | Traçat | `<path d="M0,0 L100,50" stroke="#color"/>` |

## Temes Disponibles

Canvia el tema modificant l'URL del CSS:

```html
<!-- Tema fosc (recomanat) -->
<link rel="stylesheet" href=".../theme/night.css">

<!-- Altres temes -->
<link rel="stylesheet" href=".../theme/black.css">
<link rel="stylesheet" href=".../theme/white.css">
<link rel="stylesheet" href=".../theme/league.css">
<link rel="stylesheet" href=".../theme/beige.css">
<link rel="stylesheet" href=".../theme/sky.css">
<link rel="stylesheet" href=".../theme/simple.css">
<link rel="stylesheet" href=".../theme/serif.css">
<link rel="stylesheet" href=".../theme/blood.css">
<link rel="stylesheet" href=".../theme/moon.css">
<link rel="stylesheet" href=".../theme/solarized.css">
```

## Configuració de Reveal.js

```javascript
Reveal.initialize({
    // Navegació
    hash: true,              // Afegir hash a URL per cada slide
    slideNumber: true,       // Mostrar número de diapositiva

    // Transicions
    transition: 'slide',     // none/fade/slide/convex/concave/zoom

    // Controls
    controls: true,          // Mostrar fletxes de navegació
    progress: true,          // Barra de progrés

    // Comportament
    loop: false,             // Bucle infinit
    center: true,            // Centrar contingut verticalment

    // Plugins
    plugins: [ RevealHighlight, RevealNotes ]
});
```

## Estils Personalitzats Útils

```css
/* Colors destacats */
.reveal .highlight { color: #42affa; }
.reveal .warning { color: #f0ad4e; }
.reveal .success { color: #5cb85c; }
.reveal .danger { color: #e74c3c; }

/* Badges per fases/etapes */
.fase-badge {
    display: inline-block;
    padding: 5px 15px;
    border-radius: 20px;
    font-size: 0.5em;
    margin-bottom: 10px;
}
.fase1 { background: #3498db; }
.fase2 { background: #9b59b6; }
.fase3 { background: #e67e22; }
.fase4 { background: #27ae60; }
.fase5 { background: #e74c3c; }

/* Taules més llegibles */
.reveal table { font-size: 0.7em; }
.reveal th, .reveal td { padding: 8px 15px; }

/* Codi amb scroll */
.reveal pre code { max-height: 500px; }

/* Llistes més petites */
.reveal ul { font-size: 0.85em; }
```

## Navegació

| Tecla | Acció |
|-------|-------|
| `→` / `Espai` | Següent diapositiva |
| `←` | Diapositiva anterior |
| `↓` | Diapositiva vertical següent |
| `↑` | Diapositiva vertical anterior |
| `Esc` / `O` | Vista general |
| `F` | Pantalla completa |
| `S` | Vista de presentador |
| `B` | Pantalla negra |

## Obrir la Presentació

### Opció 1: Directament al navegador
```bash
# Obrir l'arxiu HTML directament
firefox presentacio.html
# o
google-chrome presentacio.html
```

### Opció 2: Amb servidor local (recomanat per funcionalitats avançades)
```bash
# Python 3
python -m http.server 8000

# Node.js
npx serve .

# Després accedir a http://localhost:8000/presentacio.html
```

## Exportar a PDF

1. Obrir la presentació al navegador
2. Afegir `?print-pdf` a la URL: `presentacio.html?print-pdf`
3. Imprimir (Ctrl+P) → Desar com a PDF
4. Seleccionar "Paisatge" i "Sense marges"

## Recursos

- [Documentació oficial Reveal.js](https://revealjs.com/)
- [Exemples de presentacions](https://revealjs.com/demo/)
- [Repositori GitHub](https://github.com/hakimel/reveal.js)
