-- Pregunta 2: porcentaje de la población total por provincia
with poblacion as (
    select
        codigo_departamento,
        sum(poblacion) as poblacion
    from {{ ref('fct_radios_censales') }}
    group by codigo_departamento
),

provincias as (
    -- Base: la dimensión, para que cuenten también los departamentos sin población
    select
        d.codigo_provincia,
        d.nombre_provincia,
        count(*)                      as departamentos,
        sum(coalesce(p.poblacion, 0)) as poblacion
    from {{ ref('dim_departamentos') }} d
    left join poblacion p using (codigo_departamento)
    group by d.codigo_provincia, d.nombre_provincia
)

select
    row_number() over (order by poblacion desc, codigo_provincia) as ranking,
    codigo_provincia,
    nombre_provincia,
    departamentos,
    poblacion,
    round(100.0 * poblacion / sum(poblacion) over (), 2)          as porcentaje_poblacion_nacional
from provincias
