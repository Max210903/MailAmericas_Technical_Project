-- Cada hogar responde las 4 variables, así que en cada radio todas deben sumar el mismo total.
-- int_hogares_por_radio toma el total de HOGAR_H24A: si esto no se cumple, ese total no sirve para las demás.
with totales as (
    select codigo_radio, variable, sum(hogares) as total
    from {{ ref('stg_indec__censo_hogares') }}
    group by codigo_radio, variable
)

select codigo_radio
from totales
group by codigo_radio
having count(distinct total) > 1  -- totales distintos entre variables
    or count(*) <> 4              -- falta alguna variable en el radio
