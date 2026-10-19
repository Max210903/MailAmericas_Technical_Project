-- Pregunta 1: los 10 departamentos más poblados y dónde están (provincia y centroide)
with poblacion as (
    select
        codigo_departamento,
        sum(poblacion) as poblacion
    from {{ ref('fct_radios_censales') }}
    group by codigo_departamento
),

ranking as (
    select
        -- row_number + código como desempate: siempre exactamente 10 filas y orden reproducible
        row_number() over (order by p.poblacion desc, p.codigo_departamento) as ranking,
        p.codigo_departamento,
        d.nombre_departamento,
        d.nombre_provincia,
        d.latitud,
        d.longitud,
        p.poblacion,
        round(100.0 * p.poblacion / sum(p.poblacion) over (), 2)              as porcentaje_poblacion_nacional
    from poblacion p
    inner join {{ ref('dim_departamentos') }} d using (codigo_departamento)
)

select *
from ranking
where ranking <= 10
