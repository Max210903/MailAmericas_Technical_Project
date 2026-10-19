-- La población del hecho debe coincidir con la de staging: si no, el join con hogares perdió (o duplicó) personas.
with totales as (
    select
        (select sum(poblacion) from {{ ref('fct_radios_censales') }})        as poblacion_hecho,
        (select sum(poblacion) from {{ ref('stg_indec__radios_censales') }}) as poblacion_radios
)

select *
from totales
where poblacion_hecho <> poblacion_radios
