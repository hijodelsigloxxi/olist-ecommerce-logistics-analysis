"""
02_predictive_algorithm.py

Capa predictiva ligera del proyecto Olist E-commerce Logistics Analysis.

Objetivo:
Predecir si un pedido entregado llegará con retraso a partir de la vista
analytics.vw_predictive_orders_dataset.

Este script es la versión ejecutable en Python del notebook de predicción.
Permite dejar la capa predictiva reproducible fuera de Jupyter.

Uso básico:
    python scripts/02_predictive_algorithm.py

Uso guardando resultados:
    python scripts/02_predictive_algorithm.py --save-results

Requisitos:
    pip install pandas numpy sqlalchemy psycopg2-binary scikit-learn matplotlib

Notas:
- Ejecutar desde la raíz del repositorio.
- Ajustar la contraseña de PostgreSQL si no es "postgres".
- La vista analytics.vw_predictive_orders_dataset debe existir previamente.
"""

from pathlib import Path
import argparse
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

from sqlalchemy import create_engine
from sqlalchemy.exc import SQLAlchemyError

from sklearn.model_selection import train_test_split
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.pipeline import Pipeline

from sklearn.dummy import DummyClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier

from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    roc_auc_score,
    confusion_matrix,
    classification_report,
    RocCurveDisplay
)


# ============================================================
# 1. Configuración
# ============================================================

DB_USER = "postgres"
DB_PASSWORD = "postgres"  # Cambiar si se usa otra contraseña
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "olist-ecommerce-logistics-analysis"

CONNECTION_STRING = (
    f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}"
    f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

PROJECT_ROOT = Path(__file__).resolve().parents[1] if "__file__" in globals() else Path.cwd()
OUTPUTS_DIR = PROJECT_ROOT / "outputs"
OUTPUTS_DIR.mkdir(exist_ok=True)


# ============================================================
# 2. Carga de datos
# ============================================================

def load_predictive_dataset() -> pd.DataFrame:
    """Carga la vista predictiva desde PostgreSQL."""
    engine = create_engine(CONNECTION_STRING)

    query = """
    SELECT *
    FROM analytics.vw_predictive_orders_dataset;
    """

    try:
        df = pd.read_sql(query, engine)
    except SQLAlchemyError as exc:
        raise RuntimeError(
            "No se pudo cargar analytics.vw_predictive_orders_dataset. "
            "Comprueba que PostgreSQL está activo y que la vista existe."
        ) from exc

    return df


# ============================================================
# 3. Preparación del dataset
# ============================================================

def prepare_features(df: pd.DataFrame):
    """Prepara X, y, variables numéricas y categóricas."""

    df = df.copy()

    # Variable objetivo
    df["target_is_delayed"] = df["is_delayed"].astype(int)

    target = "target_is_delayed"

    features = [
        # Variables temporales previas o iniciales
        "approval_time_days",

        # Complejidad del pedido
        "number_of_items",
        "number_of_products",
        "number_of_sellers",

        # Variables económicas
        "total_items_value",
        "total_freight_value",
        "total_payment_value",

        # Variables de producto
        "avg_product_weight_g",
        "avg_product_volume_cm3",
        "total_product_weight_g",
        "total_product_volume_cm3",
        "number_of_product_categories",
        "main_product_category",

        # Variables territoriales
        "customer_state",
        "main_seller_state",
        "number_of_seller_states",
        "same_state_order",

        # Variables temporales de compra
        "purchase_year",
        "purchase_month",
        "purchase_quarter",
        "purchase_day_of_week"
    ]

    numeric_features = [
        "approval_time_days",
        "number_of_items",
        "number_of_products",
        "number_of_sellers",
        "total_items_value",
        "total_freight_value",
        "total_payment_value",
        "avg_product_weight_g",
        "avg_product_volume_cm3",
        "total_product_weight_g",
        "total_product_volume_cm3",
        "number_of_product_categories",
        "number_of_seller_states",
        "purchase_year",
        "purchase_month",
        "purchase_quarter",
        "purchase_day_of_week"
    ]

    categorical_features = [
        "main_product_category",
        "customer_state",
        "main_seller_state",
        "same_state_order"
    ]

    # Comprobación de columnas
    missing_columns = [col for col in features + [target] if col not in df.columns]
    if missing_columns:
        raise ValueError(f"Faltan columnas en el dataset predictivo: {missing_columns}")

    X = df[features].copy()
    y = df[target].copy()

    # Tratamiento simple de nulos
    for col in numeric_features:
        X[col] = X[col].fillna(X[col].median())

    for col in categorical_features:
        X[col] = X[col].fillna("Desconocido")

    return X, y, numeric_features, categorical_features


# ============================================================
# 4. Modelos y evaluación
# ============================================================

def build_preprocessor(numeric_features, categorical_features):
    """Crea el preprocesador común para todos los modelos."""
    return ColumnTransformer(
        transformers=[
            ("num", StandardScaler(), numeric_features),
            ("cat", OneHotEncoder(handle_unknown="ignore"), categorical_features)
        ]
    )


def evaluate_model(model_name, model, X_test, y_test):
    """Evalúa un modelo y devuelve métricas principales."""
    y_pred = model.predict(X_test)

    if hasattr(model, "predict_proba"):
        y_proba = model.predict_proba(X_test)[:, 1]
        roc_auc = roc_auc_score(y_test, y_proba)
    else:
        roc_auc = np.nan

    cm = confusion_matrix(y_test, y_pred)

    results = {
        "model": model_name,
        "accuracy": accuracy_score(y_test, y_pred),
        "precision": precision_score(y_test, y_pred, zero_division=0),
        "recall": recall_score(y_test, y_pred, zero_division=0),
        "f1_score": f1_score(y_test, y_pred, zero_division=0),
        "roc_auc": roc_auc,
        "tn": cm[0, 0],
        "fp": cm[0, 1],
        "fn": cm[1, 0],
        "tp": cm[1, 1],
    }

    print("\n============================================================")
    print(model_name)
    print("============================================================")
    print("Matriz de confusión:")
    print(cm)
    print("\nClassification report:")
    print(classification_report(y_test, y_pred, zero_division=0))

    return results


def train_models(X_train, X_test, y_train, y_test, numeric_features, categorical_features):
    """Entrena y evalúa Dummy, Regresión Logística y Random Forest."""

    preprocessor = build_preprocessor(numeric_features, categorical_features)

    models = {
        "Dummy Classifier": Pipeline(
            steps=[
                ("preprocessor", preprocessor),
                ("classifier", DummyClassifier(strategy="most_frequent"))
            ]
        ),

        "Regresión logística": Pipeline(
            steps=[
                ("preprocessor", preprocessor),
                ("classifier", LogisticRegression(
                    max_iter=1000,
                    class_weight="balanced",
                    random_state=42
                ))
            ]
        ),

        "Random Forest": Pipeline(
            steps=[
                ("preprocessor", preprocessor),
                ("classifier", RandomForestClassifier(
                    n_estimators=200,
                    max_depth=10,
                    min_samples_split=20,
                    min_samples_leaf=10,
                    class_weight="balanced",
                    random_state=42,
                    n_jobs=-1
                ))
            ]
        )
    }

    fitted_models = {}
    results = []

    for model_name, model in models.items():
        model.fit(X_train, y_train)
        fitted_models[model_name] = model

        model_results = evaluate_model(model_name, model, X_test, y_test)
        results.append(model_results)

    results_df = pd.DataFrame(results)
    return fitted_models, results_df


# ============================================================
# 5. Gráficos
# ============================================================

def plot_model_comparison(results_df, save_results=False):
    """Genera gráfico comparativo de métricas."""
    metrics_to_plot = ["accuracy", "precision", "recall", "f1_score", "roc_auc"]
    results_plot = results_df.set_index("model")[metrics_to_plot]

    ax = results_plot.plot(kind="bar", figsize=(10, 6))

    plt.title("Comparación de modelos predictivos")
    plt.ylabel("Valor de la métrica")
    plt.xlabel("Modelo")
    plt.xticks(rotation=0)
    plt.ylim(0, 1)
    plt.legend(title="Métrica")
    plt.tight_layout()

    if save_results:
        output_path = OUTPUTS_DIR / "predictive_model_comparison.png"
        plt.savefig(output_path, dpi=300, bbox_inches="tight")
        print(f"Gráfico guardado en: {output_path}")

    plt.show()


def plot_confusion_matrix(model, X_test, y_test, model_name="Random Forest", save_results=False):
    """Genera matriz de confusión del modelo seleccionado."""
    y_pred = model.predict(X_test)
    cm = confusion_matrix(y_test, y_pred)

    fig, ax = plt.subplots(figsize=(5, 4))
    ax.imshow(cm)

    ax.set_title(f"Matriz de confusión - {model_name}")
    ax.set_xlabel("Predicción")
    ax.set_ylabel("Valor real")

    ax.set_xticks([0, 1])
    ax.set_yticks([0, 1])
    ax.set_xticklabels(["No retrasado", "Retrasado"])
    ax.set_yticklabels(["No retrasado", "Retrasado"])

    for i in range(cm.shape[0]):
        for j in range(cm.shape[1]):
            ax.text(j, i, cm[i, j], ha="center", va="center")

    plt.tight_layout()

    if save_results:
        output_path = OUTPUTS_DIR / "random_forest_confusion_matrix.png"
        plt.savefig(output_path, dpi=300, bbox_inches="tight")
        print(f"Matriz guardada en: {output_path}")

    plt.show()


def plot_roc_curves(fitted_models, X_test, y_test, save_results=False):
    """Genera curvas ROC para regresión logística y Random Forest."""
    plt.figure(figsize=(7, 6))

    RocCurveDisplay.from_estimator(
        fitted_models["Regresión logística"],
        X_test,
        y_test,
        name="Regresión logística"
    )

    RocCurveDisplay.from_estimator(
        fitted_models["Random Forest"],
        X_test,
        y_test,
        name="Random Forest"
    )

    plt.title("Curva ROC de los modelos predictivos")
    plt.tight_layout()

    if save_results:
        output_path = OUTPUTS_DIR / "predictive_roc_curves.png"
        plt.savefig(output_path, dpi=300, bbox_inches="tight")
        print(f"Curva ROC guardada en: {output_path}")

    plt.show()


def get_random_forest_feature_importance(random_forest_model, numeric_features, categorical_features):
    """Extrae importancia de variables del Random Forest."""
    preprocessor_fitted = random_forest_model.named_steps["preprocessor"]

    categorical_names = (
        preprocessor_fitted
        .named_transformers_["cat"]
        .get_feature_names_out(categorical_features)
        .tolist()
    )

    feature_names = numeric_features + categorical_names

    importances = random_forest_model.named_steps["classifier"].feature_importances_

    feature_importance_df = pd.DataFrame({
        "feature": feature_names,
        "importance": importances
    }).sort_values("importance", ascending=False)

    return feature_importance_df


def plot_feature_importance(feature_importance_df, save_results=False):
    """Genera gráfico de importancia de variables."""
    top_features = feature_importance_df.head(15).sort_values("importance")

    plt.figure(figsize=(8, 6))
    plt.barh(top_features["feature"], top_features["importance"])
    plt.title("Principales variables predictivas - Random Forest")
    plt.xlabel("Importancia")
    plt.ylabel("Variable")
    plt.tight_layout()

    if save_results:
        output_path = OUTPUTS_DIR / "random_forest_feature_importance.png"
        plt.savefig(output_path, dpi=300, bbox_inches="tight")
        print(f"Importancia de variables guardada en: {output_path}")

    plt.show()


# ============================================================
# 6. Función principal
# ============================================================

def main():
    parser = argparse.ArgumentParser(
        description="Ejecuta la capa predictiva ligera del proyecto Olist."
    )

    parser.add_argument(
        "--save-results",
        action="store_true",
        help="Guarda métricas, matrices y gráficos en la carpeta outputs."
    )

    args = parser.parse_args()

    print("============================================================")
    print("Capa predictiva ligera - Olist E-commerce Logistics Analysis")
    print("============================================================")

    df = load_predictive_dataset()

    print("\nDimensiones del dataset predictivo:")
    print(df.shape)

    print("\nDistribución de is_delayed:")
    print(df["is_delayed"].value_counts())
    print("\nDistribución porcentual:")
    print(df["is_delayed"].value_counts(normalize=True) * 100)

    X, y, numeric_features, categorical_features = prepare_features(df)

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=0.2,
        random_state=42,
        stratify=y
    )

    print("\nDimensiones train/test:")
    print("X_train:", X_train.shape)
    print("X_test:", X_test.shape)

    print("\nDistribución del conjunto de prueba:")
    print(y_test.value_counts())

    fitted_models, results_df = train_models(
        X_train,
        X_test,
        y_train,
        y_test,
        numeric_features,
        categorical_features
    )

    print("\n============================================================")
    print("Comparación final de modelos")
    print("============================================================")
    print(results_df)

    if args.save_results:
        results_path = OUTPUTS_DIR / "predictive_model_results.csv"
        results_df.to_csv(results_path, index=False, encoding="utf-8")
        print(f"\nResultados guardados en: {results_path}")

    plot_model_comparison(results_df, save_results=args.save_results)

    random_forest_model = fitted_models["Random Forest"]

    plot_confusion_matrix(
        random_forest_model,
        X_test,
        y_test,
        model_name="Random Forest",
        save_results=args.save_results
    )

    plot_roc_curves(
        fitted_models,
        X_test,
        y_test,
        save_results=args.save_results
    )

    feature_importance_df = get_random_forest_feature_importance(
        random_forest_model,
        numeric_features,
        categorical_features
    )

    print("\n============================================================")
    print("Top 15 variables más importantes - Random Forest")
    print("============================================================")
    print(feature_importance_df.head(15))

    if args.save_results:
        importance_path = OUTPUTS_DIR / "random_forest_feature_importance.csv"
        feature_importance_df.to_csv(importance_path, index=False, encoding="utf-8")
        print(f"Importancia de variables guardada en: {importance_path}")

    plot_feature_importance(
        feature_importance_df,
        save_results=args.save_results
    )

    print("\nProceso predictivo finalizado correctamente.")


if __name__ == "__main__":
    main()
