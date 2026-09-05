# Olist E-commerce Logistics Analysis

## 1. Descripción del proyecto

Este repositorio contiene el proyecto **Arquitectura analítica para el análisis del rendimiento logístico y la predicción de retrasos en e-commerce**.

El objetivo principal es diseñar e implementar una arquitectura analítica reproducible para estudiar el rendimiento logístico de los pedidos en un marketplace de comercio electrónico. El proyecto utiliza el dataset público **Brazilian E-Commerce Public Dataset by Olist**, que contiene información sobre pedidos, clientes, vendedores, productos, pagos, reseñas, líneas de pedido y geolocalización aproximada.

El flujo de trabajo combina limpieza de datos en Python, modelado relacional en PostgreSQL, construcción de una capa analítica dimensional, visualización en Power BI y una capa predictiva ligera para explorar la predicción de retrasos logísticos.

---

## 2. Objetivos

Los objetivos principales del proyecto son:

- Analizar la estructura original del dataset Olist y sus distintas granularidades.
- Limpiar y preparar los datos originales mediante Python.
- Construir una capa relacional `core` en PostgreSQL que conserve la trazabilidad del dataset.
- Diseñar una capa analítica `analytics` basada en hechos y dimensiones.
- Calcular indicadores logísticos sobre tiempos de aprobación, entrega, retrasos, costes de envío, productos, vendedores, territorio y satisfacción del cliente.
- Crear vistas SQL reutilizables para alimentar un dashboard en Power BI.
- Desarrollar una capa predictiva ligera para evaluar si las variables disponibles permiten anticipar retrasos.

---

## 3. Dataset

El proyecto utiliza el dataset público:

**Brazilian E-Commerce Public Dataset by Olist**  
Fuente: Kaggle  
Enlace: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

Tablas principales utilizadas:

- `orders`
- `customers`
- `sellers`
- `products`
- `order_items`
- `order_payments`
- `order_reviews`
- `geolocations`

El dataset contiene información de pedidos realizados en marketplaces brasileños entre 2016 y 2018. Su interés principal para este proyecto es que permite reconstruir parcialmente el ciclo logístico del pedido: compra, aprobación, envío, entrega al cliente y comparación con la fecha estimada.

---

## 4. Arquitectura del proyecto

La arquitectura se organiza en varias capas:

```text
data/raw
   ↓
Limpieza y preparación en Python
   ↓
data/processed
   ↓
PostgreSQL - capa core
   ↓
PostgreSQL - capa analytics
   ↓
Vistas SQL
   ↓
Power BI dashboard
   ↓
Capa predictiva ligera en Python
```

### Capa `core`

La capa `core` conserva la estructura relacional principal del dataset original. Su objetivo es mantener los datos limpios, organizados y trazables, respetando la granularidad original de cada tabla.

Incluye tablas como:

- `core.orders`
- `core.customers`
- `core.sellers`
- `core.products`
- `core.order_items`
- `core.order_payments`
- `core.order_reviews`
- `core.geolocations`

### Capa `analytics`

La capa `analytics` reorganiza la información con una lógica analítica basada en tablas de hechos y dimensiones. Su objetivo es facilitar el cálculo de indicadores, la conexión con Power BI y la preparación de variables para la capa predictiva.

Tablas principales:

- `analytics.fact_orders`
- `analytics.fact_order_items`
- `analytics.dim_customer`
- `analytics.dim_seller`
- `analytics.dim_product`
- `analytics.dim_geography`
- `analytics.dim_date`
- `analytics.dim_order_status`

---

## 5. Estructura del repositorio

La estructura general del repositorio es la siguiente:

```text
olist-ecommerce-logistics-analysis/
│
├── data/
│   ├── raw/
│   └── processed/
│
├── notebooks/
│   ├── 01_data_cleaning.ipynb
│   └── 02_predictive_algorithom.ipynb
│
├── outputs/
│
├── Power BI/
│   └── dashboard.pbix
│
├── scripts/
│
├── sql/
│   ├── core/
│   ├── analytics/
│   ├── Analysis/
│   └── views/
│
├── docker-compose.yml
│
└── README.md
```

### Carpetas principales

- `data/raw`: contiene los archivos CSV originales del dataset.
- `data/processed`: contiene las tablas limpias y preparadas para PostgreSQL.
- `notebooks`: contiene los notebooks de limpieza, exploración y modelado predictivo.
- `sql/core`: scripts para crear y cargar la capa relacional `core`.
- `sql/analytics`: scripts para crear y cargar la capa analítica dimensional.
- `sql/Analysis`: consultas SQL exploratorias utilizadas para el análisis.
- `sql/views`: vistas SQL finales utilizadas para Power BI.
- `Power BI`: archivo del dashboard.
- `outputs`: imágenes, resultados o exportaciones generadas durante el proyecto.
- `docker-compose.yml`: configuración opcional para levantar PostgreSQL mediante Docker.

---

## 6. Requisitos

Para ejecutar el proyecto se recomienda disponer de:

- Python 3.11 o superior
- PostgreSQL 16
- pgAdmin o cliente SQL equivalente
- Power BI Desktop
- Docker Desktop, opcional
- Git

Librerías principales de Python:

```bash
pip install pandas numpy sqlalchemy psycopg2-binary scikit-learn matplotlib
```

---

## 7. Ejecución con PostgreSQL local

Si se utiliza una instalación local de PostgreSQL, el flujo recomendado es:

1. Crear una base de datos llamada:

```text
olist-ecommerce-logistics-analysis
```

2. Ejecutar los scripts de creación de la capa `core`:

```text
sql/core/01_create_tables_core_data.sql
```

3. Cargar los datos procesados en la capa `core`:

```text
sql/core/02_import_core_data.sql
```

4. Crear las tablas de la capa `analytics`:

```text
sql/analytics/01_Create_tables.sql
```

5. Poblar la capa `analytics`:

```text
sql/analytics/02_import_core_data.sql
```

6. Ejecutar las vistas SQL finales:

```text
sql/views/
```

7. Conectar Power BI a PostgreSQL e importar las vistas del esquema `analytics`.

---

## 8. Reproducibilidad con Docker

Docker se incorpora como apoyo a la reproducibilidad del entorno PostgreSQL. Su uso es opcional, pero permite levantar una base de datos PostgreSQL 16 sin depender completamente de una instalación local.

### Archivo `docker-compose.yml`

```yaml
version: "3.9"

services:
  postgres:
    image: postgres:16
    container_name: olist_postgres
    environment:
      POSTGRES_DB: olist-ecommerce-logistics-analysis
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./sql:/sql
      - ./data/processed:/data/processed

volumes:
  postgres_data:
```

### Levantar el contenedor

Desde la raíz del repositorio:

```bash
docker compose up -d
```

### Comprobar que el contenedor está activo

```bash
docker ps
```

### Detener el contenedor

```bash
docker compose down
```

### Datos de conexión

```text
Host: localhost
Puerto: 5432
Base de datos: olist-ecommerce-logistics-analysis
Usuario: postgres
Contraseña: postgres
```

Después de levantar PostgreSQL con Docker, los scripts SQL deben ejecutarse igual que en la instalación local.

---

## 9. Scripts SQL principales

### Capa core

```text
sql/core/01_create_tables_core_data.sql
sql/core/02_import_core_data.sql
```

Estos scripts crean y cargan las tablas relacionales del esquema `core`.

### Capa analytics

```text
sql/analytics/01_Create_tables.sql
sql/analytics/02_import_core_data.sql
```

Estos scripts crean y cargan las tablas dimensionales y de hechos del esquema `analytics`.

### Consultas de análisis

```text
sql/Analysis/
```

Incluye consultas para:

- indicadores generales;
- distribución de retrasos;
- complejidad del pedido;
- valor económico;
- rendimiento por vendedor;
- análisis por peso y volumen;
- rendimiento por categoría de producto;
- análisis geográfico;
- satisfacción del cliente;
- evolución mensual.

### Vistas SQL

```text
sql/views/
```

Contiene las vistas finales utilizadas para alimentar Power BI, entre ellas:

- `vw_general_order_performance`
- `vw_delay_distribution_delivered`
- `vw_delay_distribution_delayed`
- `vw_monthly_logistics_trends`
- `vw_seller_performance`
- `vw_product_category_performance`
- `vw_customer_state_performance`
- `vw_same_vs_different_state_performance`
- `vw_review_score_by_delivery_status`
- `vw_negative_reviews_by_delivery_status`
- `vw_predictive_orders_dataset`

---

## 10. Dashboard en Power BI

El dashboard se construye en Power BI a partir de las vistas SQL creadas sobre la capa `analytics`.

El objetivo del dashboard es monitorizar visualmente el rendimiento logístico del marketplace mediante:

- pedidos totales;
- pedidos entregados;
- pedidos retrasados;
- tasa de retraso;
- tiempo medio de aprobación;
- tiempo medio de entrega;
- retraso medio;
- distribución de retrasos;
- evolución mensual;
- análisis por producto;
- análisis por vendedor;
- análisis territorial;
- satisfacción del cliente.

Power BI se utiliza como capa de visualización. La lógica de cálculo de los indicadores se mantiene en PostgreSQL mediante consultas y vistas SQL.

---

## 11. Capa predictiva

La capa predictiva se desarrolla en Python a partir de la vista:

```sql
analytics.vw_predictive_orders_dataset
```

El objetivo es transformar el problema logístico en una tarea de clasificación binaria:

```text
0 = pedido no retrasado
1 = pedido retrasado
```

La variable objetivo es `is_delayed`.

Se excluyen variables que provocarían fuga de información, como:

- `delay_days`
- `total_delivery_time_days`
- `delivery_time_days`
- fechas reales de entrega
- `avg_review_score`

Variables utilizadas como predictores:

- variables temporales de compra;
- número de ítems;
- número de productos;
- número de vendedores;
- valor del pedido;
- coste de envío;
- valor total pagado;
- peso y volumen agregados;
- categoría principal;
- estado del cliente;
- estado del vendedor;
- relación mismo/distinto estado.

Modelos evaluados:

- `DummyClassifier`
- `LogisticRegression`
- `RandomForestClassifier`

Métricas utilizadas:

- accuracy;
- precision;
- recall;
- F1-score;
- ROC-AUC.

El objetivo de esta capa no es construir un sistema productivo, sino comprobar si la arquitectura permite generar un dataset predictivo reproducible y evaluar de forma básica la capacidad de anticipar retrasos.

---

## 12. Resultados principales

El análisis general muestra:

- 99.441 pedidos totales.
- 96.478 pedidos entregados.
- 7.826 pedidos entregados con retraso.
- Tasa global de retraso aproximada: 8,11 %.
- Tiempo medio total de entrega: 12,56 días.
- Retraso medio entre pedidos retrasados: 9,55 días.

Estos resultados muestran que la mayoría de los pedidos fueron entregados dentro del plazo estimado. Sin embargo, el grupo de pedidos retrasados es suficientemente relevante como para justificar un análisis específico por producto, vendedor, territorio, complejidad del pedido y variables temporales.

---

## 13. Autor

**Luis Ángel Soler Zamora**  
Bàtxelor en Data Science  
Universitat Carlemany  
Trabajo Final de Bàtxelor  
Septiembre de 2026
