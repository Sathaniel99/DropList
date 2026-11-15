# DropList 0.5

Addon para **World of Warcraft 3.3.5a** (Wrath of the Lich King). Solo hace una cosa: **una lista de objetos**. Añades un objeto y la lista lleva la cuenta de cuántas veces lo has añadido. Sin bosses, sin instancias, sin dificultades.

- **Autor:** Sathaniel
- **Versión:** 0.5
- **Interface:** 30300
- **Dependencias:** ninguna (Lua 5.1 puro). **ElvUI es opcional**: si está instalado, DropList usa su aspecto.
- **Tema:** se adapta a ElvUI cuando lo detecta; también funciona con el aspecto clásico de Blizzard.

---

## Instalación

1. Copia la carpeta **`DropList`** a:
   ```
   World of Warcraft\Interface\AddOns\DropList\
   ```
   Debe quedar `...\AddOns\DropList\DropList.toc`.
2. Entra al juego o escribe `/reload`.
3. Abre la lista con `/droplist` o con el botón del minimapa.

---

## Añadir objetos

Hay cuatro formas, todas llevan a lo mismo:

1. **Comando**: `/droplist add <enlace>` (pega el enlace con **Shift-clic** sobre el objeto) o `/droplist add <ID>`.
   ```
   /droplist add 49908
   /droplist add 49908 5      (añade 5 de golpe)
   ```
2. **Botón Añadir** de la ventana: usa el objeto que tengas **en el cursor**, si no el **enlace que haya en el chat** (Shift-clic en el chat sin enviarlo) y, si no, el **último objeto que haya pasado por el tooltip**. Debajo de los botones verás `Se añadirá: <objeto>` para saber exactamente qué va a entrar.
3. **Shift-clic** sobre un objeto con la ventana abierta: se añade directo (no se abre el chat).
4. **Arrastra** el objeto desde la mochila a la ventana o al botón **Añadir**.

> El botón funciona igual que el comando: pasa el ratón por cualquier objeto (bolsa, equipo, botín, subasta, enlace del chat...) y pulsa **Añadir**. El addon guarda el último objeto mostrado en el tooltip, así que no importa que al mover el ratón al botón el tooltip desaparezca.

Si añades el **mismo objeto** otra vez, no se crea otra fila: se incrementa su contador (`x2`, `x3`...).

---

## La lista

- **Buscar**: filtra por nombre o por ID.
- **X** o **clic derecho** en una fila: quita el objeto.
- **+ / −** en la fila: suben o bajan la cantidad de 1 en 1 (solo en objetos contables).
- **Deshacer**: recupera el último añadido, quitado o vaciado (hasta 30). Los **+ / −** no entran en el historial.
- **Vaciar**: borra toda la lista (pide confirmación y se puede deshacer).
- **Tooltip**: pasa el ratón por una fila para ver el objeto y su contador.

### Botones de cantidad

El addon decide solo qué fila lleva tres botones, usando los datos del cliente (`equipLoc` y `maxStack` de `GetItemInfo`):

| Objeto | Botones |
|---|---|
| Equipo con slot: armas, armaduras, abalorios, anillos, capas, reliquias, bolsas | **solo X** |
| Contables: marcas y tokens de tier, materiales (saronita), gemas, patrones, comida, pociones, objetos de misión, munición | **X, +, −** |

- En un objeto contable con **x1** se ven `[X] [+]`; el `[−]` aparece a partir de **x2**. Para quitar la fila se usa `[X]`.
- La cantidad nunca baja de 1 con `[−]`.
- Si el cliente todavía no conoce el objeto (fila `item:ID`), la fila muestra **solo X**; en cuanto el cliente lo conoce se clasifica sola y aparecen `+` y `−` si toca.
- La clasificación se guarda con la entrada, así que se mantiene entre sesiones.

---

## Comandos

| Comando | Efecto |
|---|---|
| `/droplist` o `/dl` | Abrir / cerrar la lista |
| `/droplist add <enlace\|ID> [cantidad]` | Añadir un objeto |
| `/droplist add` | Abrir la lista (sin objeto) |
| `/droplist undo` | Deshacer el último cambio |
| `/droplist reset` | Vaciar la lista (con confirmación) |
| `/droplist scale 1.2` | Escala de la ventana (0.7 – 1.5) |
| `/droplist minimap` | Mostrar / ocultar el botón del minimapa |
| `/droplist color <hex\|nombre>` | Color de acento (ej. `69ccf0`, `dorado`) |
| `/droplist opacity 0.8` | Opacidad del fondo (0.1 – 1.0) |
| `/droplist fontsize 12` | Tamaño de fuente (8 – 24; `0` = automático) |
| `/droplist theme auto\|elvui\|classic` | Aspecto de la ventana (`/reload` al cambiar) |
| `/droplist test` | Autocomprobación del addon |
| `/droplist debug` | Diagnóstico rápido (último tooltip, enlace del chat, nº de entradas) |
| `/droplist help` | Ayuda |

También `/dlist`.

---

## Aspecto (ElvUI + personalización)

DropList detecta **ElvUI** automáticamente y, si está cargado, aplica su estilo: plantillas planas, fuentes y colores de ElvUI, botones, caja de búsqueda, barra de desplazamiento, botón de cerrar y botón del minimapa. Si ElvUI no está, usa el aspecto clásico sin romper nada.

Además puedes personalizar el addon sin tocar ElvUI:

- **Color de acento**: título, cabeceras, borde de la ventana y selección de filas. Acepta un hex (`/droplist color 336699`) o un nombre: `azul`, `cian`, `verde`, `rojo`, `dorado`, `morado`, `rosa`, `naranja`, `blanco`, `gris`.
- **Opacidad del fondo**: `/droplist opacity 0.85` (también acepta `85`).
- **Tamaño de fuente**: `/droplist fontsize 14`; `0` vuelve a usar el tamaño de ElvUI (o el de Blizzard si no hay ElvUI).
- **Tema**: `/droplist theme auto` (por defecto, usa ElvUI si existe), `elvui` o `classic`. Al cambiar de tema hace falta `/reload`.

El menú del **clic derecho** en el botón del minimapa también incluye **Tema** y **Color de acento**.

---

## Datos guardados

- Preferencias (escala, minimapa, búsqueda, posición, tema, color, opacidad y fuente): cuenta.
  `WTF\Account\<cuenta>\SavedVariables\DropList.lua`
- Lista de objetos: por personaje.
  `WTF\Account\<cuenta>\<servidor>\<personaje>\SavedVariables\DropList.lua`

Las listas de la versión anterior (con boss y dificultad) se convierten solas: los objetos repetidos se agrupan en una fila y se suman las cantidades.

---

## Notas

- **Es manual a propósito**: el addon no adivina nada, tú añades lo que quieras.
- **3.3.5 no tiene buscador global de objetos**: para dar de alta un objeto necesitas su enlace, su ID o tenerlo en el cursor/tooltip. Una vez en la lista, la búsqueda por nombre funciona.
- Si el objeto aún no está en la caché del cliente, la fila aparece como `item:ID` y se completa sola (nombre, icono y color) en cuanto el cliente lo conoce.
- **Shift-clic con la ventana abierta** añade el objeto en lugar de enlazarlo en el chat. Si quieres enlazarlo, cierra la ventana primero.
- Los emblemas/monedas no son botín en 3.3.5 y no se registran.

---

## Prueba rápida en el cliente

1. `/droplist test` → `OK: N comprobaciones`.
2. `/droplist add <enlace>` → el objeto aparece en la lista.
3. Repite → sigue habiendo una fila con `x2`.
4. Pasa el ratón por un objeto (con la ventana abierta verás `Se añadirá: ...`) y pulsa **Añadir** → se añade otra vez.
5. Pulsa **X** en una fila → desaparece; pulsa **Deshacer** → vuelve.
6. Añade **49908** (Saronita primordial) o **47557** (Marca de santificación): la fila muestra `[X] [+]`, y `[−]` a partir de x2.
7. Añade un arma o un abalorio: la fila muestra **solo X**.
8. `/reload` → todo sigue ahí, con los mismos botones.
7. Con ElvUI cargado, `/droplist theme` debe decir `detectado: ElvUI`; prueba `/droplist color dorado` y `/droplist opacity 0.85`.

---

## Estructura

```
DropList/
  DropList.toc      Interface 30300, SavedVariables
  Bootstrap.lua     namespace y colores de calidad
  Config.lua        defaults, SavedVariables y migración
  Localization.lua  textos en español
  Model.lua         lista, contadores (+ / -) y deshacer
  UI/Widgets.lua    panel, botones, lista con scroll
  UI/ElvUI.lua      skin opcional de ElvUI y ajustes visuales
  UI/MainFrame.lua  ventana principal
  Minimap.lua       botón del minimapa
  SelfTest.lua      /droplist test
  Core.lua          objetos, hooks, comandos y eventos
```
