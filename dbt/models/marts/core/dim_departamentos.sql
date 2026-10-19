-- Dimensión: atributos descriptivos de cada departamento oficial (Georef). Las medidas viven en fct_radios_censales.
select
    codigo_departamento,
    nombre_departamento,
    codigo_provincia,
    nombre_provincia,
    latitud,
    longitud
from {{ ref('stg_georef__departamentos') }}
