-- Pregunta 3: qué tan concentrada está la población (curva acumulada de departamentos ordenados por población)
with poblacion as (
    select
        codigo_departamento,
        sum(poblacion) as poblacion
    from {{ ref('fct_radios_censales') }}
    group by codigo_departamento
),

acumulado as (
    -- Base: la dimensión, para que el total de departamentos incluya a los que no tienen población
    select
        row_number() over (order by coalesce(p.poblacion, 0) desc, d.codigo_departamento) as ranking,
        count(*) over ()                                                                  as total_departamentos,
        100.0 * sum(coalesce(p.poblacion, 0)) over (
            order by coalesce(p.poblacion, 0) desc, d.codigo_departamento
            rows between unbounded preceding and current row
        ) / sum(coalesce(p.poblacion, 0)) over ()                                         as porcentaje_acumulado
    from {{ ref('dim_departamentos') }} d
    left join poblacion p using (codigo_departamento)
),

cortes as (
    -- Cortes fijos: cuánta población reúnen los N departamentos más poblados
    select
        'Top ' || n || ' departamentos' as corte,
        n                               as departamentos
    from (values (10), (20), (50), (100)) as t (n)

    union all

    -- Umbrales: cuántos departamentos hacen falta para reunir el X% de la población
    select
        'Departamentos para reunir el ' || u || '% de la población',
        min(a.ranking)
    from (values (50), (80)) as t (u)
    inner join acumulado a on a.porcentaje_acumulado >= t.u
    group by t.u
)

select
    c.corte,
    c.departamentos,
    round(100.0 * c.departamentos / a.total_departamentos, 2) as porcentaje_departamentos,
    round(a.porcentaje_acumulado, 2)                          as porcentaje_poblacion
from cortes c
inner join acumulado a on a.ranking = c.departamentos
