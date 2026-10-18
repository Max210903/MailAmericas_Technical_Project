with origen as (
    select * from {{ source('georef', 'georef_departamentos') }}
)

select
    departamento_id                     as codigo_departamento,
    departamento_nombre                 as nombre_departamento,
    provincia_id                        as codigo_provincia,
    provincia_nombre                    as nombre_provincia,
    departamento_centroide_lat::numeric as latitud,
    departamento_centroide_lon::numeric as longitud
from origen
