-- Los hogares de departamentos deben coincidir con la suma de todos los radios con datos de hogares:
-- si no, el join con Georef perdió (o duplicó) hogares.
with totales as (
    select
        (select sum(hogares_total) from {{ ref('departamentos') }})         as hogares_departamentos,
        (select sum(hogares_total) from {{ ref('int_hogares_por_radio') }}) as hogares_radios
)

select *
from totales
where hogares_departamentos <> hogares_radios
