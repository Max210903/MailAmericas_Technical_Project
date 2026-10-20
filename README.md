# MailAmericas: población de Argentina y demanda potencial de e-commerce

Pipeline ELT reproducible que descarga datos públicos del Censo 2022 y de Georef, los carga en PostgreSQL, los transforma con dbt y genera un reporte desde la base. Todo se orquesta con Apache Airflow y corre en Docker.

**Reporte final:** [`reports/reporte.md`](reports/reporte.md). Responde:

1. los 10 departamentos más poblados y dónde están;
2. el porcentaje de la población por provincia;
3. qué tan concentrada está la población;
4. una métrica para logística: demanda potencial de e-commerce por departamento;

y cuantifica su confiabilidad (sección 5 del reporte).

**Documentación de dbt:** [`reports/dbt_docs.html`](reports/dbt_docs.html), generada también por el DAG. Hay que descargarla y abrirla en el navegador: contiene el grafo de linaje navegable y la descripción y los tests de cada modelo y columna.

---

## Cómo ejecutarlo

### Requisitos

- Linux o WSL2 (probado en Ubuntu 22.04) con **Docker Engine** nativo y el plugin `docker compose`. Docker Desktop no está soportado: los scripts lo detectan y se detienen.
- Si tu usuario no está en el grupo `docker`, los scripts se reejecutan con `sudo` y piden la contraseña. Para evitarlo (opcional, una sola vez): `sudo usermod -aG docker $USER` y cerrar sesión. Ten en cuenta que el grupo `docker` da permisos equivalentes a root.
- Puertos libres: `8080` (Airflow) y `5432` (warehouse).
- Conexión a internet: el DAG descarga las fuentes en cada ejecución.

### Pasos

```bash
# 1. Warehouse PostgreSQL (crea los esquemas raw, staging, intermediate y marts)
./scripts/set-up-warehouse.sh up

# 2. Airflow 2 (construye la imagen con dbt y Cosmos, y la conecta a la red del warehouse)
./scripts/set-up-airflow.sh up

# 3. (Opcional) Verificar dbt: instala paquetes, valida el proyecto y prueba la conexión
./scripts/set-up-dbt.sh up
```

4. Entrar a <http://localhost:8080> (usuario `admin`, contraseña `admin`), activar el DAG `mailamerica_pipeline` y ejecutarlo con **Trigger DAG**. También se puede lanzar por consola:

   ```bash
   docker exec mailamericas-airflow-scheduler airflow dags unpause mailamerica_pipeline
   docker exec mailamericas-airflow-scheduler airflow dags trigger mailamerica_pipeline
   ```

5. Al terminar (unos minutos), el reporte queda en `reports/reporte.md` y la documentación de dbt en `reports/dbt_docs.html`.

### Otros comandos útiles

| Comando | Qué hace |
|---|---|
| `./scripts/set-up-<airflow\|warehouse>.sh status` | Estado de los contenedores |
| `./scripts/set-up-<airflow\|warehouse>.sh logs` | Logs en vivo |
| `./scripts/set-up-<airflow\|warehouse>.sh down` | Detiene los contenedores (conserva los datos) |
| `./scripts/set-up-<airflow\|warehouse>.sh clean` | Detiene y borra volúmenes (y la imagen, en Airflow) |
| `./scripts/set-up-warehouse.sh psql` | Consola SQL del warehouse |
| `./scripts/set-up-dbt.sh <comando>` | Cualquier comando de dbt, p. ej. `build --select staging` o `test` |

---

## Arquitectura

```
                  ┌───────────────────────────── DAG mailamerica_pipeline (Airflow 2) ──────────────────────────────┐
 Fuentes públicas │  extract         load               staging ──► intermediate ──► marts        report            │
 INDEC · Georef ─►│  download ×26 ─► load_to_raw ×3 ─►  └──────── dbt con Cosmos ×18 ────────┘ ─► generate_report   │─► reports/
                  │                                                                              generate_dbt_docs │
                  └─────────────────────────────────────────────────────────────────────────────────────────────────┘
                                         │                                │
                                         ▼                                ▼
                             PostgreSQL warehouse:  raw ──► staging ──► intermediate ──► marts
```

Los grupos `staging`, `intermediate` y `marts` del DAG corresponden a las capas de dbt. Cada modelo es una tarea (`dbt build`: el modelo y sus tests). Los tests que cruzan varios modelos son tareas aparte y corren en la última capa que usan.

```
.
├── airflow/dags/
│   ├── mailamerica_pipeline.py   # DAG (TaskFlow API)
│   ├── config/sources.json       # URLs de las fuentes
│   └── templates/reporte.md.j2   # Plantilla del reporte
├── dbt/                          # Proyecto dbt: models/, tests/, seeds/, macros/
├── docker/
│   ├── airflow/                  # Dockerfile + compose de Airflow (con su propia base de metadatos)
│   └── warehouse/                # compose del warehouse + script SQL de esquemas
├── reports/
│   ├── reporte.md                # Reporte final (generado)
│   └── dbt_docs.html             # Documentación de dbt con el linaje (generada)
└── scripts/                      # set-up-airflow.sh, set-up-warehouse.sh, set-up-dbt.sh
```

**Stack:** Airflow 2.11 (LocalExecutor), dbt-core 1.12 + dbt-postgres, Astronomer Cosmos 1.15, PostgreSQL 16.

---

## Fuentes

| Fuente | Organismo | Qué aporta | Por qué |
|---|---|---|---|
| [Radios censales 2022](https://infra.datos.gob.ar/catalog/indec/dataset/50/distribution/50.1/download/radios-censales-2022.csv) | INDEC | Población y viviendas particulares por radio censal (~66 mil radios) | Es el dato oficial más reciente (Censo 2022) y el grano más fino publicado: se puede agregar a departamento o provincia sin perder nada. |
| [Departamentos (API Georef)](https://apis.datos.gob.ar/georef/api/departamentos?max=1000&campos=id,nombre,provincia,centroide&formato=csv) | Servicio de Normalización de Datos Geográficos | Lista oficial de 529 departamentos, con nombre, provincia y centroide | Responde el "dónde están" y sirve de lista de referencia: permite detectar departamentos sin datos en lugar de perderlos en silencio. |
| [Indicadores de hogares 2022](https://infra.datos.gob.ar/catalog/indec/dataset/48) (24 ZIP, uno por provincia) | INDEC | Hogares por radio: internet en la vivienda, celular con internet, computadora e índice de privación material | Es el dataset adicional para la métrica logística: mide conectividad y capacidad de compra, que es lo que diferencia la demanda de e-commerce de la población a secas. |
| Totales oficiales del Censo 2022 (seed `indec_totales_oficiales.csv`) | INDEC | Población en viviendas particulares, colectivas, en situación de calle y total censada | Referencia externa para medir la cobertura del pipeline. |

Las tres fuentes se cruzan por el código INDEC de departamento de 5 dígitos (2 de provincia + 3 de departamento), que comparten.

---

## Modelado de datos

El proyecto sigue un esquema ELT en capas: primero se carga todo tal cual, después se transforma en SQL dentro de la base.

| Capa | Esquema | Materialización | Qué hace |
|---|---|---|---|
| **raw** | `raw` | tablas | Copia literal de cada fuente, todas las columnas como texto. La carga la hace Airflow con `COPY`, sin filtros: si algo se interpreta mal, el dato original sigue disponible. La seed de totales oficiales también vive aquí. |
| **staging** | `staging` | vistas | Una vista por fuente: nombres claros, tipos, códigos con ceros a la izquierda (`lpad`) y filtro de las 4 variables de hogares que se usan. |
| **intermediate** | `intermediate` | vistas | `int_hogares_por_radio`: pivotea los hogares (una fila por radio y variable → una fila por radio con una columna por indicador). |
| **marts** | `marts` | tablas | Esquema en estrella + tablas del reporte + tabla de calidad. |

### Esquema en estrella

```
        dim_departamentos (529 filas)                     fct_radios_censales (66.503 filas)
        ─────────────────────────────                     ──────────────────────────────────
        codigo_departamento  PK   ◄──────── N:1 ──────── codigo_departamento  FK
        nombre_departamento                               codigo_radio         PK
        codigo_provincia, nombre_provincia                poblacion, viviendas
        latitud, longitud                                 hogares_total, hogares_con_internet,
                                                          hogares_con_celular_internet,
                                                          hogares_con_computadora, hogares_sin_privacion
```

- **`dim_departamentos`**: solo atributos descriptivos, tomados de Georef. La provincia va desnormalizada en la dimensión: son 24 y no tienen atributos propios, así que una `dim_provincias` no aportaría nada.
- **`fct_radios_censales`**: solo medidas, al grano radio censal (el más fino que publica el INDEC). Une radios y hogares con `full outer join` para no perder a nadie: hay 155 radios sin hogares (todos con población 0) y 1 radio con hogares que no figura en el archivo de radios.
- **Tablas del reporte** (`rpt_*`): cada una agrega `fct ⋈ dim` al nivel que necesita su pregunta. **`dq_cobertura_y_calidad`** compara el resultado contra referencias externas.

```
staging                              intermediate             marts
stg_georef__departamentos ───────────────────────────────►   dim_departamentos ──┐
stg_indec__radios_censales ──────────────────────────────┐                       ├─► rpt_top10_departamentos
stg_indec__censo_hogares ──► int_hogares_por_radio ──────┴► fct_radios_censales ─┼─► rpt_poblacion_por_provincia
                                                                                 ├─► rpt_concentracion_poblacion
seed indec_totales_oficiales ─────────────────────────────────────────────────── ├─► rpt_demanda_ecommerce
                                                                                 └─► dq_cobertura_y_calidad
```

**Por qué así:** separar atributos (dimensión) de medidas (hecho) es la forma estándar de modelar para análisis y hace explícito el grano de cada tabla. Conservar el grano radio, en lugar de agregar directamente a departamento, deja abierta la puerta a análisis más finos (por ejemplo, zonas de reparto) sin rehacer el modelo. Las tablas del reporte quedan como consultas cortas y testeadas, y el código Python del reporte solo las lee y les da formato.

---

## Decisiones importantes y alternativas descartadas

| Decisión | Alternativa descartada | Por qué |
|---|---|---|
| **Dos `docker compose` independientes** (Airflow con su propia base de metadatos, y el warehouse), unidos por una red de Docker | Un solo compose con una sola base | Separa la metadata de Airflow de los datos del negocio: se puede recrear Airflow sin tocar el warehouse, y al revés. |
| **dbt en un virtualenv propio** dentro de la imagen de Airflow | Instalar dbt junto a Airflow, o un contenedor aparte de dbt | Evita conflictos de dependencias entre Airflow y dbt, y no exige orquestar un contenedor extra. |
| **Astronomer Cosmos** para ejecutar dbt | Una sola tarea `dbt build` con bash | Cada modelo y sus tests aparecen como tareas en Airflow: se ve exactamente qué falló y se puede reintentar solo esa parte. |
| **Carga verbatim a `raw`** (todo texto, sin filtros) | Filtrar y tipar al cargar | El dato original queda auditable en la base; toda la lógica queda en dbt, versionada y testeada. |
| **Métrica exacta** con dos dimensiones (hogares con celular con internet × % sin privación) | Estimar "hogares con internet *y* sin privación" multiplicando proporciones | El censo no publica ese cruce. La estimación suponía independencia entre ambas variables, algo que no se puede verificar y que probablemente es falso. Se prefirió no inventar datos. |
| **Celular con internet** como medida de conectividad | Internet en la vivienda, o "internet o celular" | Celular con internet cubre el 89% de los hogares, y combinarlo con internet en la vivienda agrega solo 5.272 hogares en todo el país. Además, es como se compra online. |
| **Esquema en estrella** | Un único mart agregado por departamento | Conserva el grano radio y separa atributos de medidas (ver [Modelado](#modelado-de-datos)). |
| **Reporte en Markdown generado por el DAG** | Metabase o Superset, notebook de Jupyter, HTML con gráficos | Se lee directo en GitHub sin levantar nada, se regenera en cada ejecución y no suma servicios ni dependencias. |

---

## Confiabilidad: qué tan confiable es y cómo se mide

Se mide de dos formas, ambas dentro del pipeline:

**1. Cobertura e integridad contra referencias externas** (tabla `dq_cobertura_y_calidad`, sección 5 del reporte):

| Indicador | Valor | Referencia | % |
|---|---:|---:|---:|
| Población en viviendas particulares | 45.618.784 | 45.618.787 (INDEC) | 99,99999 |
| Población total censada | 45.618.784 | 45.892.285 (INDEC) | 99,40 |
| Departamentos con población | 527 | 529 (Georef) | 99,62 |
| Radios con datos de hogares | 66.347 | 66.502 | 99,77 |
| Radios con departamento en Georef | 66.502 | 66.502 | 100 |

- **Las 3 personas de diferencia** con el total oficial están explicadas: son un hogar de 3 personas en el radio 860630701, que figura en el archivo de hogares pero no en el de radios. Sus hogares sí entran al reporte.
- **El 0,6% faltante de la población censada** es la población en viviendas colectivas (267.793: cárceles, geriátricos, hospitales) y en situación de calle (5.705). El INDEC no la publica por radio, así que queda fuera del alcance.
- **Los 2 departamentos sin población** son Antártida Argentina e Islas del Atlántico Sur.

**2. Tests de dbt (65 tests)** que corren en cada ejecución, como tareas de Airflow. Si alguno falla, el reporte no se genera:

- **Claves:** `unique` y `not_null` en las claves de cada modelo.
- **Integridad referencial:** todo radio y todo hogar pertenece a un departamento de Georef (`relationships`).
- **Conservación de totales:** la población y los hogares del hecho suman exactamente lo mismo que staging, así que los joins no pierden ni duplican filas. Las provincias suman el total nacional y sus porcentajes, 100.
- **Consistencia interna de la fuente:** las 4 variables de hogares suman el mismo total en cada radio.
- **Dominios:** valores aceptados de variables y segmentos, y rangos válidos.

---

## Limitaciones y qué haría con más tiempo

**Limitaciones**

- **Solo población en viviendas particulares** (99,4% del total censado). Es la única que el INDEC publica por radio.
- **El censo no publica cruces entre variables:** no se sabe cuántos hogares conectados son además hogares sin privación. Por eso la métrica cruza las dos dimensiones a nivel departamento, no a nivel hogar.
- **El corte de capacidad de compra es binario** (promedio nacional, 65,52%). Departamentos cerca del umbral, como Lomas de Zamora (65,17%) o Quilmes (64,64%), cambiarían de segmento con un corte apenas distinto.
- **La métrica mide demanda *potencial*,** no compras cross-border reales: no hay datos públicos de envíos internacionales por departamento.
- **Los datos son de 2022.** El centroide del departamento es una aproximación de su ubicación: en departamentos grandes, la población puede estar lejos del centroide.

**Con más tiempo**

- **Análisis de sensibilidad** de los cortes de segmentación, o reemplazarlos por una variable continua (por ejemplo, hogares conectados × % sin privación).
- Sumar fuentes: **establecimientos productivos (CEP XXI)** para la demanda B2B, y la red vial o los centros de distribución para medir distancias reales.
- Un **mapa** de los segmentos con las coordenadas que ya están en `rpt_demanda_ecommerce`.
- **CI** (GitHub Actions) que corra `dbt build` en cada PR, y secretos en un `.env` en lugar de credenciales por defecto.
- **Cachear descargas** para no volver a bajar más de 130 MB (solo el CSV de radios) si la fuente no cambió.

---

## Uso de IA

Usé Claude Code (Anthropic) como asistente durante todo el proyecto: para proponer la estructura, escribir borradores de código (DAG, modelos dbt, scripts) y explorar los datos.

Cómo lo validé:

- **Cada cambio pasó por revisión antes de aplicarse,** en pasos chicos, con un commit por paso.
- **Toda cifra se verificó contra la base** con consultas directas antes de darla por buena, y contra fuentes externas cuando fue posible (totales oficiales del INDEC).
- **Los tests de dbt** codifican esas verificaciones para que se repitan en cada ejecución.
- **Se descartaron propuestas que no resistieron la revisión:** por ejemplo, la primera versión de la métrica estimaba un cruce que el censo no publica, y se reemplazó por una métrica exacta.
