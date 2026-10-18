with origen as (
    select * from {{ source('indec', 'indec_radios_censales') }}
)

select
    codigo                                          as codigo_radio,
    lpad(cod_prov, 2, '0')                          as codigo_provincia,
    lpad(cod_prov, 2, '0') || lpad(cod_dep, 3, '0') as codigo_departamento,
    fraccion,
    radio,
    pob_tot_p::integer                              as poblacion,
    viv_tot_p::integer                              as viviendas
from origen
-- wkt (geometría del radio) se descarta: no se usa en el análisis
