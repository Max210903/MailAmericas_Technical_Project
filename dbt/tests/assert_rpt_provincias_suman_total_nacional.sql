-- Las provincias deben sumar toda la población del hecho, y sus porcentajes 100
-- (con tolerancia por redondeo: hasta 0,005 por provincia).
with totales as (
    select
        (select sum(poblacion) from {{ ref('rpt_poblacion_por_provincia') }})                     as poblacion_provincias,
        (select sum(poblacion) from {{ ref('fct_radios_censales') }})                             as poblacion_hecho,
        (select sum(porcentaje_poblacion_nacional) from {{ ref('rpt_poblacion_por_provincia') }}) as suma_porcentajes,
        (select count(*) from {{ ref('rpt_poblacion_por_provincia') }})                           as provincias
)

select *
from totales
where poblacion_provincias <> poblacion_hecho
   or abs(suma_porcentajes - 100) > provincias * 0.005
