-- Pregunta 4: demanda potencial de e-commerce por departamento, en dos dimensiones exactas del censo:
-- tamaño del mercado digital (hogares con celular con internet) y capacidad de compra (% de hogares sin privación)
with hogares as (
    select
        codigo_departamento,
        sum(hogares_total)                as hogares_total,
        sum(hogares_con_celular_internet) as hogares_conectados,
        sum(hogares_sin_privacion)        as hogares_sin_privacion
    from {{ ref('fct_radios_censales') }}
    group by codigo_departamento
),

departamentos as (
    -- Base: la dimensión, para que aparezcan también los departamentos sin hogares
    select
        d.codigo_departamento,
        d.nombre_departamento,
        d.nombre_provincia,
        d.latitud,
        d.longitud,
        coalesce(h.hogares_total, 0)         as hogares_total,
        coalesce(h.hogares_conectados, 0)    as hogares_conectados,
        coalesce(h.hogares_sin_privacion, 0) as hogares_sin_privacion
    from {{ ref('dim_departamentos') }} d
    left join hogares h using (codigo_departamento)
),

indicadores as (
    select
        *,
        row_number() over (order by hogares_conectados desc, codigo_departamento)         as ranking_mercado,
        100.0 * hogares_conectados / nullif(hogares_total, 0)                             as pct_hogares_conectados,
        100.0 * hogares_sin_privacion / nullif(hogares_total, 0)                          as pct_hogares_sin_privacion,
        100.0 * hogares_conectados / sum(hogares_conectados) over ()                      as porcentaje_mercado_nacional,
        100.0 * sum(hogares_conectados) over (
            order by hogares_conectados desc, codigo_departamento
            rows between unbounded preceding and current row
        ) / sum(hogares_conectados) over ()                                               as porcentaje_acumulado,
        -- Corte de capacidad de compra: el promedio nacional
        100.0 * sum(hogares_sin_privacion) over () / sum(hogares_total) over ()           as pct_sin_privacion_nacional
    from departamentos
)

select
    ranking_mercado,
    codigo_departamento,
    nombre_departamento,
    nombre_provincia,
    latitud,
    longitud,
    hogares_total,
    hogares_conectados,
    round(pct_hogares_conectados, 2)      as pct_hogares_conectados,
    round(pct_hogares_sin_privacion, 2)   as pct_hogares_sin_privacion,
    round(porcentaje_mercado_nacional, 2) as porcentaje_mercado_nacional,
    round(porcentaje_acumulado, 2)        as porcentaje_acumulado,
    -- Mercado principal: los departamentos necesarios para reunir el 80% de los hogares conectados
    -- (el acumulado antes de sumar el departamento todavía no llegaba al 80%)
    case
        when hogares_total = 0 then 'Sin hogares'
        when porcentaje_acumulado - porcentaje_mercado_nacional < 80
            and pct_hogares_sin_privacion >= pct_sin_privacion_nacional then 'Prioritario'
        when porcentaje_acumulado - porcentaje_mercado_nacional < 80 then 'Volumen con baja capacidad de compra'
        when pct_hogares_sin_privacion >= pct_sin_privacion_nacional then 'Nicho con capacidad de compra'
        else 'Baja prioridad'
    end                                   as segmento
from indicadores
