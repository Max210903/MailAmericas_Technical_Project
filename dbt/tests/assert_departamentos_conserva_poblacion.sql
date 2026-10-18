-- La población de departamentos debe coincidir con la suma de todos los radios censales:
-- si no, el join con Georef perdió (o duplicó) personas.
with totales as (
    select
        (select sum(poblacion) from {{ ref('departamentos') }})              as poblacion_departamentos,
        (select sum(poblacion) from {{ ref('stg_indec__radios_censales') }}) as poblacion_radios
)

select *
from totales
where poblacion_departamentos <> poblacion_radios
