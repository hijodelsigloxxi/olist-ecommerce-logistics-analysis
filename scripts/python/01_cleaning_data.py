import pandas as pd
import os
import numpy as np

# ------------------------------------------------------------
# 0. Directorio de trabajo
# ------------------------------------------------------------
# Se establece la carpeta raíz del proyecto como directorio de trabajo.
# Esto permite usar rutas relativas desde la raíz del repositorio.

os.chdir("C:/Users/lusoz/Desktop/tfg")

# Se crea la carpeta de datos procesados si todavía no existe.
os.makedirs("data/processed", exist_ok=True)


# ------------------------------------------------------------
# 1. Carga de datos originales
# ------------------------------------------------------------
# Se cargan todos los archivos CSV originales del dataset Olist.
# Estos archivos se mantienen intactos en la carpeta data/raw.
# Las transformaciones se guardarán posteriormente en data/processed.

customers = pd.read_csv("data/raw/datasets-Brazilian E-Commerce Public Dataset by Olist/olist_customers_dataset.csv")
geolocations = pd.read_csv("data/raw/datasets-Brazilian E-Commerce Public Dataset by Olist/olist_geolocation_dataset.csv")
order_items = pd.read_csv("data/raw/datasets-Brazilian E-Commerce Public Dataset by Olist/olist_order_items_dataset.csv")
order_payments = pd.read_csv("data/raw/datasets-Brazilian E-Commerce Public Dataset by Olist/olist_order_payments_dataset.csv")
order_reviews = pd.read_csv("data/raw/datasets-Brazilian E-Commerce Public Dataset by Olist/olist_order_reviews_dataset.csv")
order_dataset = pd.read_csv("data/raw/datasets-Brazilian E-Commerce Public Dataset by Olist/olist_orders_dataset.csv")
products = pd.read_csv("data/raw/datasets-Brazilian E-Commerce Public Dataset by Olist/olist_products_dataset.csv")
sellers = pd.read_csv("data/raw/datasets-Brazilian E-Commerce Public Dataset by Olist/olist_sellers_dataset.csv")
product_category_name_translation = pd.read_csv("data/raw/datasets-Brazilian E-Commerce Public Dataset by Olist/product_category_name_translation.csv")


# ------------------------------------------------------------
# 2. Limpieza de customers
# ------------------------------------------------------------
# La tabla customers contiene información territorial básica de los clientes.
# Se normalizan los campos de ciudad y estado para evitar diferencias de formato.
# Además, el prefijo postal se convierte a string porque funciona como identificador
# geográfico, no como variable numérica de análisis.

customers["customer_city"] = customers["customer_city"].str.lower().str.strip()
customers["customer_state"] = customers["customer_state"].str.upper().str.strip()
customers["customer_zip_code_prefix"] = customers["customer_zip_code_prefix"].astype(str)

customers.to_csv("data/processed/customers.csv", index=False)


# ------------------------------------------------------------
# 3. Limpieza de geolocations
# ------------------------------------------------------------
# La tabla geolocations contiene múltiples registros por prefijo postal.
# Primero se eliminan duplicados exactos.
# Después se agrupa por geolocation_zip_code_prefix para obtener una única fila
# por prefijo postal.
#
# Para latitud y longitud se calcula la media.
# Para ciudad y estado se conserva el primer valor disponible.
#
# Esta tabla procesada será usada como tabla de referencia geográfica
# en el modelo relacional core.

geolocations_clean = geolocations.drop_duplicates().copy()

geolocations_zip = (
    geolocations_clean
    .groupby("geolocation_zip_code_prefix", as_index=False)
    .agg({
        "geolocation_lat": "mean",
        "geolocation_lng": "mean",
        "geolocation_city": "first",
        "geolocation_state": "first"
    })
)

# El prefijo postal se convierte a string para mantener coherencia
# con customers y sellers.
geolocations_zip["geolocation_zip_code_prefix"] = geolocations_zip["geolocation_zip_code_prefix"].astype(str)

# Normalización básica de ciudad y estado.
geolocations_zip["geolocation_city"] = geolocations_zip["geolocation_city"].str.lower().str.strip()
geolocations_zip["geolocation_state"] = geolocations_zip["geolocation_state"].str.upper().str.strip()

geolocations_zip.to_csv("data/processed/geolocations.csv", index=False)


# ------------------------------------------------------------
# 4. Limpieza de order_items
# ------------------------------------------------------------
# La tabla order_items contiene las líneas de pedido.
# Cada fila representa un producto dentro de un pedido.
# Se convierte shipping_limit_date a formato datetime para facilitar
# posteriores análisis temporales.

order_items["shipping_limit_date"] = pd.to_datetime(
    order_items["shipping_limit_date"],
    errors="coerce"
)

order_items.to_csv("data/processed/order_items.csv", index=False)


# ------------------------------------------------------------
# 5. Limpieza de order_payments
# ------------------------------------------------------------
# La tabla order_payments no requiere transformaciones estructurales en esta fase.
# Se exporta igualmente a data/processed para mantener una carpeta procesada
# completa y coherente con el resto del flujo.

order_payments.to_csv("data/processed/order_payments.csv", index=False)


# ------------------------------------------------------------
# 6. Limpieza de order_reviews
# ------------------------------------------------------------
# La tabla order_reviews contiene las valoraciones de los clientes.
# Se convierten las columnas temporales a formato datetime.
# Los campos review_comment_title y review_comment_message pueden contener nulos,
# ya que muchos clientes dejan puntuación sin escribir comentario.

order_reviews["review_creation_date"] = pd.to_datetime(
    order_reviews["review_creation_date"],
    errors="coerce"
)

order_reviews["review_answer_timestamp"] = pd.to_datetime(
    order_reviews["review_answer_timestamp"],
    errors="coerce"
)

order_reviews.to_csv("data/processed/order_reviews.csv", index=False)


# ------------------------------------------------------------
# 7. Limpieza de orders
# ------------------------------------------------------------
# La tabla orders es la tabla central del ciclo logístico del pedido.
# Se convierten todas las columnas temporales a formato datetime.
# Algunas fechas pueden contener nulos porque ciertos pedidos pueden no haber sido
# aprobados, enviados o entregados.

order_dataset["order_purchase_timestamp"] = pd.to_datetime(
    order_dataset["order_purchase_timestamp"],
    errors="coerce"
)

order_dataset["order_approved_at"] = pd.to_datetime(
    order_dataset["order_approved_at"],
    errors="coerce"
)

order_dataset["order_delivered_carrier_date"] = pd.to_datetime(
    order_dataset["order_delivered_carrier_date"],
    errors="coerce"
)

order_dataset["order_delivered_customer_date"] = pd.to_datetime(
    order_dataset["order_delivered_customer_date"],
    errors="coerce"
)

order_dataset["order_estimated_delivery_date"] = pd.to_datetime(
    order_dataset["order_estimated_delivery_date"],
    errors="coerce"
)

order_dataset.to_csv("data/processed/orders.csv", index=False)


# ------------------------------------------------------------
# 8. Limpieza de products
# ------------------------------------------------------------
# La tabla products contiene información descriptiva y física de los productos.
# Se detectaron algunos valores de peso igual a 0.
# Como un producto físico no debería tener peso cero, estos valores se sustituyen
# por NaN para tratarlos como valores ausentes.

products.loc[products["product_weight_g"] == 0, "product_weight_g"] = np.nan

products.to_csv("data/processed/products.csv", index=False)


# ------------------------------------------------------------
# 9. Limpieza de sellers
# ------------------------------------------------------------
# La tabla sellers contiene información territorial de los vendedores.
# Se normalizan ciudad y estado, y se convierte el prefijo postal a string
# para mantener coherencia con customers y geolocations.

sellers["seller_zip_code_prefix"] = sellers["seller_zip_code_prefix"].astype(str)
sellers["seller_city"] = sellers["seller_city"].str.lower().str.strip()
sellers["seller_state"] = sellers["seller_state"].str.upper().str.strip()

sellers.to_csv("data/processed/sellers.csv", index=False)


# ------------------------------------------------------------
# 10. Exportación de tabla de traducción de categorías
# ------------------------------------------------------------
# Esta tabla permite traducir las categorías de producto del portugués al inglés.
# No se transforma en esta fase, pero se guarda en data/processed por coherencia.

product_category_name_translation.to_csv(
    "data/processed/product_category_name_translation.csv",
    index=False
)


# ------------------------------------------------------------
# 11. Mensaje final
# ------------------------------------------------------------

print("Proceso de limpieza finalizado.")
print("Archivos procesados guardados en data/processed/")