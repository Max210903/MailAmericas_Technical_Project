-- Confiabilidad del reporte: cobertura frente a los totales oficiales del INDEC e integridad de los joins.
-- porcentaje = valor / referencia; diferencia = referencia - valor
with oficiales as (
    select
        sum(valor) filter (where indicador = 'poblacion_viviendas_particulares') as poblacion_viviendas_particulares,
        sum(valor) filter (where indicador = 'poblacion_censada')                as poblacion_censada
    from {{ ref('indec_totales_oficiales') }}
),

hecho as (
    select
        sum(poblacion)     as poblacion,
        sum(hogares_total) as hogares
    from {{ ref('fct_radios_censales') }}
),

departamentos as (
    select
        count(*)                                                                as total,
        count(*) filter (where coalesce(f.poblacion, 0) > 0)                    as con_poblacion,
        count(*) filter (where coalesce(f.hogares, 0) > 0)                      as con_hogares,
        string_agg(d.nombre_departamento, ', ') filter (where coalesce(f.poblacion, 0) = 0) as sin_poblacion,
        string_agg(d.nombre_departamento, ', ') filter (where coalesce(f.hogares, 0) = 0)   as sin_hogares
    from {{ ref('dim_departamentos') }} d
    left join (
        select
            codigo_departamento,
            sum(poblacion)     as poblacion,
            sum(hogares_total) as hogares
        from {{ ref('fct_radios_censales') }}
        group by codigo_departamento
    ) f using (codigo_departamento)
),

radios as (
    -- Radios del archivo de radios: cuántos tienen datos de hogares y cuántos caen en un departamento de Georef
    select
        count(*)                                                        as total,
        count(*) filter (where h.codigo_radio is not null)              as con_hogares,
        coalesce(sum(r.poblacion) filter (where h.codigo_radio is null), 0) as poblacion_sin_hogares,
        count(*) filter (where d.codigo_departamento is not null)       as con_departamento_georef
    from {{ ref('stg_indec__radios_censales') }} r
    left join {{ ref('int_hogares_por_radio') }} h using (codigo_radio)
    left join {{ ref('dim_departamentos') }} d on d.codigo_departamento = r.codigo_departamento
),

radios_solo_hogares as (
    -- Radios con hogares que no figuran en el archivo de radios (entran al hecho con población 0)
    select
        coalesce(sum(h.hogares_total), 0)  as hogares,
        string_agg(h.codigo_radio, ', ')   as codigos
    from {{ ref('int_hogares_por_radio') }} h
    left join {{ ref('stg_indec__radios_censales') }} r using (codigo_radio)
    where r.codigo_radio is null
),

indicadores as (
    select
        1                                        as orden,
        'Cobertura'                              as dimension,
        'Población en viviendas particulares'    as indicador,
        h.poblacion::bigint                      as valor,
        o.poblacion_viviendas_particulares::bigint as referencia,
        'Referencia: total oficial del INDEC. La diferencia corresponde a los radios que figuran solo en el '
            || 'archivo de hogares: ' || coalesce(s.codigos, 'ninguno') || '.' as detalle
    from hecho h, oficiales o, radios_solo_hogares s

    union all

    select
        2,
        'Cobertura',
        'Población total censada',
        h.poblacion::bigint,
        o.poblacion_censada::bigint,
        'Referencia: total oficial del INDEC. Quedan fuera la población en viviendas colectivas y en situación '
            || 'de calle: el archivo de radios solo publica población en viviendas particulares.'
    from hecho h, oficiales o

    union all

    select
        3,
        'Cobertura',
        'Departamentos con población',
        d.con_poblacion::bigint,
        d.total::bigint,
        'Referencia: departamentos de Georef. Sin población: ' || coalesce(d.sin_poblacion, 'ninguno') || '.'
    from departamentos d

    union all

    select
        4,
        'Cobertura',
        'Departamentos con hogares',
        d.con_hogares::bigint,
        d.total::bigint,
        'Referencia: departamentos de Georef. Sin hogares: ' || coalesce(d.sin_hogares, 'ninguno') || '.'
    from departamentos d

    union all

    select
        5,
        'Integridad',
        'Radios censales con datos de hogares',
        r.con_hogares::bigint,
        r.total::bigint,
        'Referencia: radios del archivo de radios. Población en los radios sin hogares: '
            || r.poblacion_sin_hogares || ' personas.'
    from radios r

    union all

    select
        6,
        'Integridad',
        'Radios censales con departamento en Georef',
        r.con_departamento_georef::bigint,
        r.total::bigint,
        'Referencia: radios del archivo de radios. Un radio sin departamento quedaría fuera del reporte.'
    from radios r

    union all

    select
        7,
        'Integridad',
        'Hogares en radios ausentes del archivo de radios',
        s.hogares::bigint,
        h.hogares::bigint,
        'Referencia: hogares del hecho. Se conservan en el hecho con población 0. Radios: '
            || coalesce(s.codigos, 'ninguno') || '.'
    from radios_solo_hogares s, hecho h
)

select
    orden,
    dimension,
    indicador,
    valor,
    referencia,
    referencia - valor                                 as diferencia,
    round(100.0 * valor / nullif(referencia, 0), 2)    as porcentaje,
    detalle
from indicadores
