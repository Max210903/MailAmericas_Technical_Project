with origen as (
    select * from {{ source('indec', 'indec_censo_hogares') }}
)

select
    codigo                                          as codigo_radio,
    lpad(cod_prov, 2, '0')                          as codigo_provincia,
    lpad(cod_prov, 2, '0') || lpad(cod_dep, 3, '0') as codigo_departamento,
    cod_variable                                    as variable,
    cod_categoria::integer                          as codigo_categoria,
    categoria,
    cantidad::integer                               as hogares
from origen
-- Solo las variables de la métrica de e-commerce (el archivo trae 30)
where cod_variable in ('HOGAR_H24A', 'HOGAR_H24B', 'HOGAR_H24C', 'HOGAR_IPMH')
