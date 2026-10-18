"""
Pipeline de población de Argentina por departamento.

Extrae fuentes públicas (INDEC, Georef), las carga al esquema raw del warehouse,
las transforma con dbt y genera el reporte final.
"""

import json
from datetime import datetime
from pathlib import Path

import requests
from airflow.decorators import dag, task, task_group

# Fuentes públicas: cada una se descarga y se carga tal cual a raw.<nombre>
SOURCES_FILE = Path(__file__).parent / "config" / "sources.json"
SOURCES = json.loads(SOURCES_FILE.read_text(encoding="utf-8"))

# Descargas dentro del contenedor (no montado: se vuelven a bajar en cada ejecución)
DATA_DIR = Path("/opt/airflow/data")


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
    def download(source: str, url: str) -> str:
        """Descarga el archivo tal cual a data/<source>/ y devuelve la ruta local."""
        target_dir = DATA_DIR / source
        target_dir.mkdir(parents=True, exist_ok=True)

        # Nombre del archivo: el de la URL (p. ej. 02-caba-2022.zip); si la URL es una API sin extensión, <source>.csv
        filename = url.split("?")[0].rsplit("/", 1)[-1]
        if "." not in filename:
            filename = f"{source}.csv"
        target = target_dir / filename

        # Descarga en streaming (el CSV de radios pesa ~131 MB) y escribe a un temporal:
        # si falla a mitad de camino, no queda un archivo corrupto con el nombre final
        tmp = target.with_suffix(target.suffix + ".part")
        with requests.get(url, stream=True, timeout=(10, 300)) as response:
            response.raise_for_status()
            with tmp.open("wb") as f:
                for chunk in response.iter_content(chunk_size=1024 * 1024):
                    f.write(chunk)
        tmp.replace(target)

        return str(target)

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
                extracted[name] = (
                    download.override(task_id=name).partial(source=name).expand(url=cfg["urls"])
                )
            else:
                extracted[name] = download.override(task_id=name)(source=name, url=cfg["url"])
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
