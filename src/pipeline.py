"""Dag04-opgave: implementér en reproducerbar batch-pipeline."""
from pathlib import Path
import sys
import duckdb

DB_PATH = Path("data/warehouse/taxi_20556.duckdb")

STEPS = (
    ("dimensions", Path("sql/02_dimensions.sql")),
    ("fact", Path("sql/03_fact_trip.sql")),
    ("aggregate", Path("sql/04_aggregates.sql")),
)

def load_statements(connection: duckdb.DuckDBPyConnection, sql_path: Path) -> list[str]:
    """Læser og parser en SQL-fil, og returnerer en liste af statements."""
    if not sql_path.exists():
        raise FileNotFoundError(f"Kritisk fejl: Filen {sql_path} mangler.")
        
    sql = sql_path.read_text(encoding="utf-8")
    statements = [item.query for item in connection.extract_statements(sql)]
    
    if not statements:
        raise ValueError(f"Kritisk fejl: Filen {sql_path} er tom eller har ingen kørbare statements.")
        
    return statements

def run_step(connection: duckdb.DuckDBPyConnection, step_name: str, statements: list[str]) -> None:
    """Kører statements for et specifikt trin."""
    print(f"\n=== Starter trin: {step_name} ===")
    for i, statement in enumerate(statements, start=1):
        print(f" -> Udfører statement {i}/{len(statements)}...")
        result = connection.execute(statement)
        
        if result is not None and result.description:
            df = result.fetchdf()
            if not df.empty:
                print(df.head(5).to_string(index=False))

def main() -> None:
    """Kører hele builden i en sikker transaktion."""
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(DB_PATH))
    
    try:
        print("Validerer afhængigheder...")
        parsed_steps = []
        for name, path in STEPS:
            statements = load_statements(con, path)
            parsed_steps.append((name, statements))
            
        print("Starter database-transaktion...")
        con.execute("BEGIN TRANSACTION")
        
        for name, statements in parsed_steps:
            run_step(con, name, statements)
            
        con.execute("COMMIT")
        print("\n✅ SUCCESS: Pipeline fuldført! Databasen er opdateret.")

        Path("output").mkdir(exist_ok=True)
        
        con.execute("COPY (SELECT * FROM agg_daily_borough_revenue) TO 'output/borough_revenue.csv' (HEADER, DELIMITER ',')")
        con.execute("COPY (SELECT * FROM agg_hourly_borough_revenue) TO 'output/hourly_borough_revenue.csv' (HEADER, DELIMITER ',')")
        
    except Exception as e:
        print(f"\n❌ FEJL I PIPELINE: {e}")
        try:
            con.execute("ROLLBACK")
            print("⚠️ Transaktion rullet tilbage. Databasen er forblevet uændret.")
        except Exception as rollback_err:
            print(f"Kunne ikke rulle tilbage: {rollback_err}")
        sys.exit(1)
    finally:
        con.close()

if __name__ == "__main__":
    main()