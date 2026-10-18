with departamentos as (
    select * from {{ ref('stg_georef__departamentos') }}
),

-- Cada fuente se agrupa por departamento antes del join, para no multiplicar filas
poblacion as (
    select
        codigo_departamento,
        sum(poblacion) as poblacion,
        sum(viviendas) as viviendas,
        count(*)       as radios
    from {{ ref('stg_indec__radios_censales') }}
    group by codigo_departamento
),

hogares as (
    select
        codigo_departamento,
        sum(hogares_total)                   as hogares_total,
        sum(hogares_con_internet)            as hogares_con_internet,
        sum(hogares_con_celular_internet)    as hogares_con_celular_internet,
        sum(hogares_con_computadora)         as hogares_con_computadora,
        sum(hogares_sin_privacion)           as hogares_sin_privacion,
        sum(hogares_digitalizados_estimados) as hogares_digitalizados_estimados,
        sum(hogares_digitalizados_min)       as hogares_digitalizados_min,
        sum(hogares_digitalizados_max)       as hogares_digitalizados_max
    from {{ ref('int_hogares_por_radio') }}
    group by codigo_departamento
)

-- Base: la lista oficial de Georef, para que ningún departamento quede afuera sin que se note
select
    d.codigo_departamento,
    d.nombre_departamento,
    d.codigo_provincia,
    d.nombre_provincia,
    d.latitud,
    d.longitud,
    coalesce(p.poblacion, 0)                       as poblacion,
    coalesce(p.viviendas, 0)                       as viviendas,
    coalesce(p.radios, 0)                          as radios,
    coalesce(h.hogares_total, 0)                   as hogares_total,
    coalesce(h.hogares_con_internet, 0)            as hogares_con_internet,
    coalesce(h.hogares_con_celular_internet, 0)    as hogares_con_celular_internet,
    coalesce(h.hogares_con_computadora, 0)         as hogares_con_computadora,
    coalesce(h.hogares_sin_privacion, 0)           as hogares_sin_privacion,
    coalesce(h.hogares_digitalizados_estimados, 0) as hogares_digitalizados_estimados,
    coalesce(h.hogares_digitalizados_min, 0)       as hogares_digitalizados_min,
    coalesce(h.hogares_digitalizados_max, 0)       as hogares_digitalizados_max,
    p.codigo_departamento is not null              as tiene_poblacion,
    h.codigo_departamento is not null              as tiene_hogares
from departamentos d
left join poblacion p using (codigo_departamento)
left join hogares h using (codigo_departamento)
