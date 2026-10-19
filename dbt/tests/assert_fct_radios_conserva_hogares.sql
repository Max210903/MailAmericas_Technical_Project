-- Los hogares del hecho deben coincidir con los de int_hogares_por_radio: si no, el join con radios perdió (o duplicó) hogares.
with totales as (
    select
        (select sum(hogares_total) from {{ ref('fct_radios_censales') }})   as hogares_hecho,
        (select sum(hogares_total) from {{ ref('int_hogares_por_radio') }}) as hogares_radios
)

select *
from totales
where hogares_hecho <> hogares_radios
