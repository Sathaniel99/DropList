# DropList 0.5

**Una lista de objetos, nada más.** Añades un objeto y DropList lleva la cuenta de cuántas veces lo has añadido.

Addon para **World of Warcraft 3.3.5a** (Wrath of the Lich King). Sin bosses, sin instancias, sin loot tables: tú decides qué entra en la lista.

- **Autor:** Sathaniel
- **Versión:** 0.5
- **Interface:** 30300
- **Dependencias:** ninguna (Lua 5.1 puro).
- **Aspecto:** tema oscuro propio, cinco paletas, color de acento, opacidad y tamaño de fuente configurables.
- **Categoría:** JcE & Enfrentamiento de Jefes (principal), Miscelánea (secundaria).
- **Idioma:** interfaz en español.

---

## Qué hace

- **Añadir objetos** de cuatro formas: comando, botón, Shift-clic o arrastrando desde la mochila.
- **Contadores automáticos**: si repites un objeto no se duplica la fila, sube el contador (`x2`, `x3`…).
- **Botones por fila**: `[X]` para quitar y `[+]` / `[−]` para ajustar la cantidad de 1 en 1.
- **Deshacer** el último añadido, quitado o vaciado (hasta 30 pasos).
- **Buscador** por nombre o por ID.
- **Filtros** por tipo: todo, equipo y objetos contables.
- **Filas con calidad**: barra lateral e icono del objeto, con franjas alternas para leer mejor la lista.
- **Ventana redimensionable** y columnas ajustables arrastrando sus separadores.
- **Datos por personaje** y preferencias por cuenta.

---

## Instalación

1. Copia la carpeta **`DropList`** a:
   ```
   World of Warcraft\Interface\AddOns\DropList\
   ```
   Debe quedar `...\AddOns\DropList\DropList.toc`.
2. Entra al juego o escribe `/reload`.
3. Abre la lista con `/droplist` o con el botón del minimapa.

**Requisitos:** World of Warcraft 3.3.5a (Interface `30300`), sin librerías externas.

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
>
> El botón del enlace de objeto aparece para calidades poco común o superior en solitario, y raro o superior en grupo/raid. Se puede activar o desactivar con `/droplist tooltip`.

Si añades el **mismo objeto** otra vez, no se crea otra fila: se incrementa su contador (`x2`, `x3`...).

---

## La lista

- **Buscar**: filtra por nombre o por ID.
- **Filtros**: `Todo`, `Equipo` y `Objetos` (los objetos sin clasificar cuentan como equipo). Se combinan con el buscador.
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
| `/droplist tooltip` | Mostrar u ocultar el botón Añadir en los tooltips |
| `/droplist filter all\|equip\|stack` | Filtrar la lista por tipo |
| `/droplist palette <nombre>` | Paleta de colores de la interfaz |
| `/droplist test` | Autocomprobación del addon |
| `/droplist debug` | Diagnóstico rápido (último tooltip, enlace del chat, nº de entradas) |
| `/droplist help` | Ayuda |

También `/dlist`.

---

## Aspecto

DropList usa un tema oscuro propio. El color de acento se aplica al título, las cabeceras, el borde de la ventana, el buscador, las filas y el botón del minimapa.

- **Paletas**: `/droplist palette obsidiana|cuero|cian|dorado|esmeralda`. Cada paleta cambia el fondo y el acento a la vez.
- **Color de acento**: acepta un hex (`/droplist color 336699`) o un nombre: `azul`, `cian`, `verde`, `rojo`, `dorado`, `morado`, `rosa`, `naranja`, `blanco`, `gris`. Ajustarlo a mano marca la paleta como `personalizado`.
- **Opacidad del fondo**: `/droplist opacity 0.85` (también acepta `85`).
- **Tamaño de fuente**: `/droplist fontsize 14`; `0` vuelve al tamaño por defecto.
- **Botón en tooltips**: `/droplist tooltip` activa o desactiva el botón Añadir de los enlaces de objeto.
- **Tamaño y columnas**: arrastra la esquina inferior derecha para redimensionar (440–760 × 380–820) y los separadores de `Objeto` / `Cant.` para ajustar el ancho.

El menú del **clic derecho** en el botón del minimapa también incluye **Paleta**, **Botón del minimapa**, **Botón en tooltips** y **Color de acento**.

---

## Datos guardados

- Preferencias (escala, minimapa, búsqueda, posición, paleta, color, opacidad, fuente, filtro, tamaño, columnas y botón de tooltip): cuenta.
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
9. Prueba `/droplist palette esmeralda`, `/droplist filter equip`, `/droplist color dorado`, `/droplist opacity 0.85` y `/droplist fontsize 14`; después `/droplist fontsize 0` debe devolver las fuentes a su tamaño original.
10. Redimensiona la ventana desde la esquina y arrastra los separadores de columnas; `/reload` debe conservar el tamaño y los anchos.

---

## Estructura

```
DropList/
  DropList.toc      Interface 30300, SavedVariables
  Bootstrap.lua     namespace y colores de calidad
  Config.lua        defaults, SavedVariables y migración
  Localization.lua  textos en español
  Model.lua         lista, contadores (+ / -) y deshacer
  UI/Widgets.lua    panel, botones, lista con scroll y buscador
  UI/Skin.lua       tema oscuro, color de acento y tipografía
  UI/MainFrame.lua  ventana principal
  Minimap.lua       botón del minimapa
  TooltipButton.lua botón Añadir en el tooltip del chat
  SelfTest.lua      /droplist test
  Core.lua          objetos, hooks, comandos y eventos
```
