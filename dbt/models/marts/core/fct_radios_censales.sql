with radios as (
    select * from {{ ref('stg_indec__radios_censales') }}
),

hogares as (
    select * from {{ ref('int_hogares_por_radio') }}
)

-- Hecho: medidas del Censo 2022 al grano más fino publicado (radio censal).
-- full outer join: hay radios con población y sin hogares particulares, y radios con hogares que no
-- figuran en el archivo de radios; así no se pierde ninguna persona ni ningún hogar
select
    coalesce(r.codigo_radio, h.codigo_radio)               as codigo_radio,
    coalesce(r.codigo_departamento, h.codigo_departamento) as codigo_departamento,
    coalesce(r.poblacion, 0)                               as poblacion,
    coalesce(r.viviendas, 0)                               as viviendas,
    coalesce(h.hogares_total, 0)                           as hogares_total,
    coalesce(h.hogares_con_internet, 0)                    as hogares_con_internet,
    coalesce(h.hogares_con_celular_internet, 0)            as hogares_con_celular_internet,
    coalesce(h.hogares_con_computadora, 0)                 as hogares_con_computadora,
    coalesce(h.hogares_sin_privacion, 0)                   as hogares_sin_privacion
from radios r
full outer join hogares h using (codigo_radio)
