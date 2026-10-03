# Probar el nuevo runtime de RORCC en un proyecto existente

Objetivo: validar verification loop, resume/checkpoints, event trace y run audit
sin poner en riesgo el proyecto.

## 0. Recomendación

Haz la primera prueba en un clone desechable del proyecto real. Si usas tu copia
normal, parte de un working tree limpio y crea una rama de prueba.

```bash
git status --short
git switch -c test/rorcc-runtime
```

No hagas la prueba directamente sobre `main` ni sobre producción.

## 1. Actualizar RORCC dentro del proyecto

Desde tu clone de `ror-command-center`:

```bash
git switch main
git pull

./install.sh --dry-run /ruta/al/proyecto
./install.sh --force --backup /ruta/al/proyecto
```

El `--dry-run` debe revisarse antes de ejecutar la instalación real.

Después:

```bash
cd /ruta/al/proyecto
git status --short
```

Confirma que los cambios corresponden al framework RORCC y no a archivos de
negocio inesperados.

## 2. Probar primero el router sin usar modelos

Usa un cambio pequeño y reversible que tenga sentido en ese proyecto.

```bash
rorcc workflow new-feature --plan \
  --request "Cambiar un texto visible de la interfaz sin modificar lógica"
```

Revisa que:

- clasifique el trabajo de forma proporcional;
- no cree specs/ADRs innecesarios;
- muestre sólo las fases que realmente aplican;
- la fase de desarrollo indique verification cuando corresponda.

`--plan` no llama modelos ni modifica el proyecto.

## 3. Probar el verification loop

Primero usa un verificador real y rápido del proyecto. Ejemplos:

RSpec:

```bash
export RORCC_VERIFY_CMD="bundle exec rspec spec/ruta/del_spec.rb"
```

Minitest:

```bash
export RORCC_VERIFY_CMD="bin/rails test test/ruta/del_test.rb"
```

Luego ejecuta un cambio pequeño:

```bash
rorcc workflow new-feature --auto \
  --request "Cambiar un texto visible de la interfaz sin modificar lógica"
```

Esperado:

1. RORCC ejecuta la fase.
2. Ejecuta el verificador determinista.
3. Si pasa, continúa.
4. Si falla, usa ese fallo como evidencia para corregir.
5. No entra en retries ilimitados.

Al terminar:

```bash
unset RORCC_VERIFY_CMD
```

### Prueba opcional del retry

Sólo en el clone/rama desechable:

```bash
export RORCC_VERIFY_CMD='test -f tmp/rorcc-verifier-pass || (mkdir -p tmp && touch tmp/rorcc-verifier-pass && exit 1)'
```

Ese comando falla la primera vez y pasa la segunda. Sirve para comprobar que el
retry es acotado y que la segunda verificación puede completar la fase.

Borra luego el archivo temporal y limpia la variable:

```bash
rm -f tmp/rorcc-verifier-pass
unset RORCC_VERIFY_CMD
```

## 4. Probar pausa y resume

Inicia el workflow en modo interactivo:

```bash
rorcc workflow new-feature \
  --request "Cambiar un texto visible de la interfaz sin modificar lógica"
```

Cuando aparezca una fase, usa `q` para detener el workflow.

Después:

```bash
rorcc workflow resume latest
```

Esperado:

- reutiliza el mismo run;
- no vuelve a clasificar desde cero;
- conserva las fases ya completadas;
- continúa desde lo pendiente;
- valida que branch, HEAD y definición del workflow sigan siendo compatibles.

Si RORCC detecta que el repositorio cambió, debe bloquear el resume en vez de
continuar silenciosamente. Usa `--force` sólo después de revisar esa diferencia.

## 5. Revisar el event trace

Localiza el último run:

```bash
RUN_ID="$(ls -1 .rorcc/runs | sort -r | head -1)"
echo "$RUN_ID"
```

Revisa sus eventos:

```bash
cat ".rorcc/runs/$RUN_ID/events.jsonl"
```

Debes ver eventos importantes como inicio/fin de workflow y fases, verification,
retry, gates o resume. No debe existir telemetría externa ni dumps completos de
prompts.

## 6. Probar el run audit

```bash
rorcc runs audit --last 20
```

Esperado:

- número de runs completos, fallidos e incompletos;
- retries;
- fallos del verifier;
- fases que repiten retries.

Con menos de cinco runs, RORCC debe advertir que todavía no hay evidencia
suficiente para cambiar router o skills.

## 7. Criterio de aceptación

Considera aprobada la prueba cuando:

- el `--plan` sigue siendo proporcional;
- un verifier real puede aprobar y rechazar una fase;
- los retries son limitados;
- `workflow resume latest` continúa el run correcto;
- `events.jsonl` explica qué ocurrió;
- `runs audit` sólo lee evidencia y no modifica RORCC;
- los tests normales del proyecto siguen pasando.

## 8. Después de la prueba

Revisa:

```bash
git status
git diff
```

Conserva sólo los cambios que realmente quieras incorporar. Si utilizaste un
clone desechable, elimínalo cuando termines; es la forma más segura de hacer esta
primera validación.

La primera prueba debe enfocarse en comprobar el runtime, no en desarrollar una
feature grande.
