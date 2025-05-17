#  Amazon Prime Video Content Analysis (ETL + SQL Analytics)

This repository showcases a complete data analytics pipeline built on the **Medallion Architecture (Bronze → Silver → Gold)** to analyze Amazon Prime Video content using SQL Server.

The project involves structured data engineering, cleaning, modeling, and insight generation through SQL queries, designed for both BI reporting and ad-hoc analysis.

---


---

##  ETL Pipeline

The project follows a layered approach:

| Layer       | Description |
|-------------|-------------|
| **Bronze**  | Raw CSV data ingested into SQL Server (`amazonprime_raw`) via Python |
| **Silver**  | Cleaned and normalized data (e.g., duration buckets, ratings, director/cast/genre split tables) |
| **Gold**    | Business-ready views (`vw_amazonprime_summary`, `vw_amazonprime_full`) for reporting |

---

##  Analytical Questions Covered

A total of **12 insights** are answered using SQL queries, such as:

1. Which director has directed the most movies and TV shows?
2. What is the genre-wise duration distribution?
3. Who are the most common director–actor collaborators?
4. What percentage of movies fall into each duration bucket?
5. Genre and rating breakdowns over time

See [`queries.sql`](scripts/queries.sql) for full details.

---

##  Tools & Tech Stack

- **Python** (Pandas + pyodbc) — for data ingestion
- **SQL Server Express** — for storage and querying
- **T-SQL** — for transformations and insights
- **ER/Star Schema Modeling**
- **Medallion Architecture** — for scalable ETL design

---

##  Future Scope

- Integration with Power BI or Tableau for dynamic dashboards
- Add temporal analysis using `date_added`
- Apply fuzzy matching to improve name normalization
- Automate pipeline via stored procedures or Airflow

---

##  References

- Dataset Source: [Kaggle - Amazon Prime Titles](https://www.kaggle.com/datasets/shivamb/amazon-prime-movies-and-tv-shows)
- ETL Pattern: Databricks Medallion Architecture




