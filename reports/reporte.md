# Población de Argentina y demanda potencial de e-commerce

_Generado el 2026-10-19 05:54 por el DAG `mailamerica_pipeline` a partir del warehouse. No editar a mano: se reescribe en cada ejecución._

**Fuentes:** INDEC, Censo 2022 (radios censales y hogares) y Georef (departamentos y sus centroides).
**Población:** población en viviendas particulares, la única que el INDEC publica por radio censal (ver [Confiabilidad](#5-confiabilidad)).

## Resumen

- **45.618.784 personas** en **529 departamentos**.
- Los 10 departamentos más poblados reúnen el **20,17%** de la población, y con 48 departamentos (9,07% del total) se cubre la mitad del país.
- Buenos Aires concentra el **38,16%** de la población.
- **82 departamentos prioritarios** para e-commerce reúnen el **48,53%** de los hogares conectados del país.
- El reporte cubre el **99,40%** de la población censada; lo que falta es población fuera de viviendas particulares.

## 1. Los 10 departamentos más poblados

| # | Departamento | Provincia | Población | % nacional | Ubicación (lat, lon) |
|---:|---|---|---:|---:|---|
| 1 | La Matanza | Buenos Aires | 1.837.168 | 4,03 | -34,7703, -58,6254 |
| 2 | Capital | Córdoba | 1.498.060 | 3,28 | -31,4168, -64,1836 |
| 3 | Rosario | Santa Fe | 1.337.958 | 2,93 | -33,1178, -60,7232 |
| 4 | La Plata | Buenos Aires | 756.074 | 1,66 | -35,0038, -58,0178 |
| 5 | Lomas de Zamora | Buenos Aires | 685.644 | 1,50 | -34,7550, -58,4241 |
| 6 | General Pueyrredón | Buenos Aires | 660.569 | 1,45 | -37,9657, -57,7430 |
| 7 | Quilmes | Buenos Aires | 631.774 | 1,38 | -34,7350, -58,2769 |
| 8 | Capital | Salta | 624.003 | 1,37 | -24,8898, -65,2713 |
| 9 | Capital | Tucumán | 587.289 | 1,29 | -26,8332, -65,2170 |
| 10 | Almirante Brown | Buenos Aires | 583.209 | 1,28 | -34,8356, -58,3674 |

La ubicación es el centroide del departamento según Georef. Consulta: [`rpt_top10_departamentos.sql`](../dbt/models/marts/reporting/rpt_top10_departamentos.sql)

## 2. Población por provincia

| # | Provincia | Departamentos | Población | % nacional |
|---:|---|---:|---:|---:|
| 1 | Buenos Aires | 135 | 17.408.906 | 38,16 |
| 2 | Córdoba | 26 | 3.812.064 | 8,36 |
| 3 | Santa Fe | 19 | 3.519.059 | 7,71 |
| 4 | Ciudad Autónoma de Buenos Aires | 15 | 3.095.454 | 6,79 |
| 5 | Mendoza | 18 | 2.030.773 | 4,45 |
| 6 | Tucumán | 17 | 1.727.337 | 3,79 |
| 7 | Salta | 23 | 1.434.225 | 3,14 |
| 8 | Entre Ríos | 17 | 1.415.097 | 3,10 |
| 9 | Misiones | 17 | 1.273.347 | 2,79 |
| 10 | Corrientes | 25 | 1.209.671 | 2,65 |
| 11 | Chaco | 25 | 1.124.603 | 2,47 |
| 12 | Santiago del Estero | 27 | 1.057.749 | 2,32 |
| 13 | San Juan | 19 | 819.445 | 1,80 |
| 14 | Jujuy | 16 | 809.364 | 1,77 |
| 15 | Río Negro | 13 | 747.697 | 1,64 |
| 16 | Neuquén | 16 | 708.578 | 1,55 |
| 17 | Formosa | 9 | 605.507 | 1,33 |
| 18 | Chubut | 15 | 589.454 | 1,29 |
| 19 | San Luis | 9 | 540.548 | 1,18 |
| 20 | Catamarca | 16 | 427.625 | 0,94 |
| 21 | La Rioja | 18 | 382.453 | 0,84 |
| 22 | La Pampa | 22 | 359.193 | 0,79 |
| 23 | Santa Cruz | 7 | 335.677 | 0,74 |
| 24 | Tierra del Fuego, Antártida e Islas del Atlántico Sur | 5 | 184.958 | 0,41 |

Consulta: [`rpt_poblacion_por_provincia.sql`](../dbt/models/marts/reporting/rpt_poblacion_por_provincia.sql)

## 3. Concentración de la población

| Corte | Departamentos | % de departamentos | % de población |
|---|---:|---:|---:|
| Top 10 departamentos | 10 | 1,89 | 20,17 |
| Top 20 departamentos | 20 | 3,78 | 30,87 |
| Departamentos para reunir el 50% de la población | 48 | 9,07 | 50,07 |
| Top 50 departamentos | 50 | 9,45 | 51,07 |
| Top 100 departamentos | 100 | 18,90 | 69,99 |
| Departamentos para reunir el 80% de la población | 149 | 28,17 | 80,11 |

La población está muy concentrada: el 1,89% de los departamentos reúne el 20,17% de las personas. Para una red logística, pocos nodos alcanzan a la mayor parte de la demanda potencial.

Consulta: [`rpt_concentracion_poblacion.sql`](../dbt/models/marts/reporting/rpt_concentracion_poblacion.sql)

## 4. Métrica logística: demanda potencial de e-commerce

**Qué mide.** Cruza la población con los datos de hogares del Censo 2022 en dos dimensiones, ambas conteos exactos del censo:

- **Tamaño del mercado digital:** hogares con celular con internet (89,24% de los hogares del país).
- **Capacidad de compra:** porcentaje de hogares sin privación material (65,52% a nivel nacional).

**Por qué.** MailAmericas hace la última milla del e-commerce cross-border: sus envíos llegan a hogares que compran online. La población sola no distingue dónde se compra. La conectividad casi no varía entre departamentos, mientras que la capacidad de compra sí, y mucho. Cruzar ambas dimensiones indica dónde conviene priorizar capacidad de reparto.

**Segmentos.** Mercado principal = los departamentos que hacen falta para reunir el 80% de los hogares conectados. Capacidad alta = porcentaje de hogares sin privación mayor o igual al promedio nacional.

| Segmento | Departamentos | Hogares conectados | % del mercado |
|---|---:|---:|---:|
| Prioritario | 82 | 6.899.750 | 48,53 |
| Volumen con baja capacidad de compra | 54 | 4.492.861 | 31,60 |
| Baja prioridad | 248 | 1.673.896 | 11,77 |
| Nicho con capacidad de compra | 143 | 1.151.696 | 8,10 |
| Sin hogares | 2 | 0 | 0,00 |

**Los 15 mercados digitales más grandes:**

| # | Departamento | Provincia | Hogares conectados | % conectados | % sin privación | Segmento |
|---:|---|---|---:|---:|---:|---|
| 1 | La Matanza | Buenos Aires | 524.202 | 90,91 | 58,82 | Volumen con baja capacidad de compra |
| 2 | Capital | Córdoba | 506.974 | 91,60 | 73,34 | Prioritario |
| 3 | Rosario | Santa Fe | 455.666 | 90,49 | 68,33 | Prioritario |
| 4 | La Plata | Buenos Aires | 277.583 | 93,04 | 71,50 | Prioritario |
| 5 | General Pueyrredón | Buenos Aires | 239.970 | 92,43 | 73,76 | Prioritario |
| 6 | Lomas de Zamora | Buenos Aires | 213.659 | 91,07 | 65,17 | Volumen con baja capacidad de compra |
| 7 | Quilmes | Buenos Aires | 195.349 | 91,00 | 64,64 | Volumen con baja capacidad de compra |
| 8 | La Capital | Santa Fe | 185.228 | 90,02 | 66,09 | Prioritario |
| 9 | Almirante Brown | Buenos Aires | 171.312 | 91,56 | 60,80 | Volumen con baja capacidad de compra |
| 10 | Capital | Salta | 169.313 | 89,91 | 58,84 | Volumen con baja capacidad de compra |
| 11 | Merlo | Buenos Aires | 166.025 | 90,90 | 53,88 | Volumen con baja capacidad de compra |
| 12 | Capital | Tucumán | 165.033 | 88,76 | 61,72 | Volumen con baja capacidad de compra |
| 13 | Moreno | Buenos Aires | 164.492 | 90,76 | 50,47 | Volumen con baja capacidad de compra |
| 14 | Confluencia | Neuquén | 156.860 | 91,93 | 71,93 | Prioritario |
| 15 | Lanús | Buenos Aires | 154.519 | 92,00 | 73,76 | Prioritario |

**Limitaciones de la métrica.** El censo publica cada variable por separado: no se sabe cuántos hogares conectados son además hogares sin privación, por lo que las dos dimensiones se cruzan a nivel departamento y no a nivel hogar. El corte de capacidad es binario, así que un departamento cerca del promedio nacional puede cambiar de segmento. No incluye datos de compras cross-border reales.

Consulta: [`rpt_demanda_ecommerce.sql`](../dbt/models/marts/reporting/rpt_demanda_ecommerce.sql)

## 5. Confiabilidad

| Dimensión | Indicador | Valor | Referencia | % | Detalle |
|---|---|---:|---:|---:|---|
| Cobertura | Población en viviendas particulares | 45.618.784 | 45.618.787 | 100,00 | Referencia: total oficial del INDEC. La diferencia corresponde a los radios que figuran solo en el archivo de hogares: 860630701. |
| Cobertura | Población total censada | 45.618.784 | 45.892.285 | 99,40 | Referencia: total oficial del INDEC. Quedan fuera la población en viviendas colectivas y en situación de calle: el archivo de radios solo publica población en viviendas particulares. |
| Cobertura | Departamentos con población | 527 | 529 | 99,62 | Referencia: departamentos de Georef. Sin población: Antártida Argentina, Islas del Atlántico Sur. |
| Cobertura | Departamentos con hogares | 527 | 529 | 99,62 | Referencia: departamentos de Georef. Sin hogares: Antártida Argentina, Islas del Atlántico Sur. |
| Integridad | Radios censales con datos de hogares | 66.347 | 66.502 | 99,77 | Referencia: radios del archivo de radios. Población en los radios sin hogares: 0 personas. |
| Integridad | Radios censales con departamento en Georef | 66.502 | 66.502 | 100,00 | Referencia: radios del archivo de radios. Un radio sin departamento quedaría fuera del reporte. |
| Integridad | Hogares en radios ausentes del archivo de radios | 1 | 15.932.302 | 0,00 | Referencia: hogares del hecho. Se conservan en el hecho con población 0. Radios: 860630701. |

Además, cada modelo de dbt tiene tests (claves únicas, relaciones entre fuentes, conservación de totales en los joins) que corren dentro del DAG: si alguno falla, este reporte no se genera.

Consulta: [`dq_cobertura_y_calidad.sql`](../dbt/models/marts/quality/dq_cobertura_y_calidad.sql)