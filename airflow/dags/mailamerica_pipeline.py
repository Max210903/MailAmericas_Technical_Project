"""
Pipeline de población de Argentina por departamento.

Extrae fuentes públicas (INDEC, Georef), las carga al esquema raw del warehouse,
las transforma con dbt y genera el reporte final.
"""

import json
from datetime import datetime
from pathlib import Path

from airflow.decorators import dag, task, task_group

# Fuentes públicas: cada una se descarga y se carga tal cual a raw.<nombre>
SOURCES_FILE = Path(__file__).parent / "config" / "sources.json"
SOURCES = json.loads(SOURCES_FILE.read_text(encoding="utf-8"))


@dag(
    dag_id="mailamerica_pipeline",
    description="Población por departamento + demanda potencial de e-commerce",
    start_date=datetime(2026, 1, 1),
    schedule=None,  # ejecución manual: los datos del censo no cambian
    catchup=False,
    default_args={"owner": "data-engineering", "retries": 2},
    tags=["indec", "georef", "dbt"],
    doc_md=__doc__,
)
def mailamerica_pipeline():

    @task
    def download(url: str) -> str:
        return url  # temporal: luego descargará el archivo y devolverá la ruta local

    @task
    def load_to_raw(files, table: str) -> str:
        return table  # temporal: luego cargará los archivos a raw.<table>

    @task.bash
    def dbt_deps() -> str:
        return "echo 'pendiente: dbt deps'"

    @task.bash
    def dbt_build() -> str:
        return "echo 'pendiente: dbt build'"

    @task
    def generate_report() -> None:
        pass  # temporal: luego generará el reporte desde los marts

    @task_group
    def extract() -> dict:
        extracted = {}
        for name, cfg in SOURCES.items():
            if "urls" in cfg:
                # Varias URLs (un ZIP por provincia): una instancia mapeada por archivo
                extracted[name] = download.override(task_id=name).expand(url=cfg["urls"])
            else:
                extracted[name] = download.override(task_id=name)(url=cfg["url"])
        return extracted

    @task_group
    def load(extracted: dict) -> list:
        # Cada fuente se carga apenas termina su propia descarga (la dependencia sale del XCom)
        return [
            load_to_raw.override(task_id=name)(files=files, table=name)
            for name, files in extracted.items()
        ]

    @task_group
    def transform():
        dbt_deps() >> dbt_build()

    @task_group
    def report():
        generate_report()

    load(extract()) >> transform() >> report()


mailamerica_pipeline()
