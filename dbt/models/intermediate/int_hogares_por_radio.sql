with hogares as (
    select * from {{ ref('stg_indec__censo_hogares') }}
),

por_radio as (
    -- coalesce: el censo omite las categorías con 0 hogares
    select
        codigo_radio,
        codigo_departamento,
        coalesce(sum(hogares) filter (where variable = 'HOGAR_H24A'), 0)                          as hogares_total,
        coalesce(sum(hogares) filter (where variable = 'HOGAR_H24A' and codigo_categoria = 1), 0) as hogares_con_internet,
        coalesce(sum(hogares) filter (where variable = 'HOGAR_H24B' and codigo_categoria = 1), 0) as hogares_con_celular_internet,
        coalesce(sum(hogares) filter (where variable = 'HOGAR_H24C' and codigo_categoria = 1), 0) as hogares_con_computadora,
        coalesce(sum(hogares) filter (where variable = 'HOGAR_IPMH' and codigo_categoria = 1), 0) as hogares_sin_privacion
    from hogares
    group by codigo_radio, codigo_departamento
)

select
    *,
    -- Hogares con internet Y sin privación: el censo no publica el cruce, se estima suponiendo
    -- independencia dentro del radio (conservador si ambas variables están correlacionadas)
    hogares_con_internet::numeric * hogares_sin_privacion / hogares_total      as hogares_digitalizados_estimados,
    -- Cotas exactas (Fréchet): el valor real está siempre en este rango
    greatest(0, hogares_con_internet + hogares_sin_privacion - hogares_total)  as hogares_digitalizados_min,
    least(hogares_con_internet, hogares_sin_privacion)                         as hogares_digitalizados_max
from por_radio
