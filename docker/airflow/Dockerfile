FROM apache/airflow:2.11.2-python3.12

# Dependencias extra, fijadas con el archivo de constraints oficial de esta versión de Airflow
# para no romper sus dependencias. AIRFLOW_VERSION y PYTHON_VERSION vienen definidas en la imagen base.
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir \
      "apache-airflow==${AIRFLOW_VERSION}" \
      -r /requirements.txt \
      --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION%.*}.txt"
