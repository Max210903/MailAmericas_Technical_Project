with hogares as (
    select * from {{ ref('stg_indec__censo_hogares') }}
)

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
