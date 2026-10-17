FROM apache/airflow:2.11.2-python3.12

# Dependencias extra, fijadas con el archivo de constraints oficial de esta versión de Airflow
# para no romper sus dependencias. AIRFLOW_VERSION y PYTHON_VERSION vienen definidas en la imagen base.
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir \
      "apache-airflow==${AIRFLOW_VERSION}" \
      -r /requirements.txt \
      --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION%.*}.txt"

# dbt en un virtualenv propio para no mezclar sus dependencias con las de Airflow.
# Solo se enlaza el ejecutable "dbt" en el PATH (no el python del venv).
ARG DBT_CORE_VERSION=1.12.6
ARG DBT_POSTGRES_VERSION=1.11.0
RUN python -m venv /home/airflow/dbt-venv \
 && /home/airflow/dbt-venv/bin/pip install --no-cache-dir \
      "dbt-core==${DBT_CORE_VERSION}" "dbt-postgres==${DBT_POSTGRES_VERSION}" \
 && ln -s /home/airflow/dbt-venv/bin/dbt /home/airflow/.local/bin/dbt
