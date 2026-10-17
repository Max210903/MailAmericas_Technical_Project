-- Se ejecuta una sola vez, cuando el volumen del warehouse está vacío.
CREATE SCHEMA IF NOT EXISTS raw;           -- datos tal cual llegan de las fuentes (los carga Airflow)
CREATE SCHEMA IF NOT EXISTS staging;       -- limpieza y tipado 1:1 por fuente (dbt)
CREATE SCHEMA IF NOT EXISTS intermediate;  -- uniones y lógica reutilizable (dbt)
CREATE SCHEMA IF NOT EXISTS marts;         -- modelo final y tablas del reporte (dbt)
