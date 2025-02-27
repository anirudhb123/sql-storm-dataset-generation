
WITH MovieData AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliases,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        COUNT(DISTINCT ca.id) AS cast_count
    FROM
        aka_title t
    LEFT JOIN aka_name ak ON ak.person_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name c ON c.id = mc.company_id
    LEFT JOIN cast_info ca ON ca.movie_id = t.id
    WHERE
        t.production_year > 2000
    GROUP BY
        t.id, t.title, t.production_year
),

ProductionDetails AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        md.aliases,
        md.keywords,
        md.companies,
        md.cast_count,
        EXTRACT(MONTH FROM DATE '2024-10-01') AS current_month
    FROM
        MovieData md
)

SELECT
    pd.title,
    pd.production_year,
    pd.aliases,
    pd.keywords,
    pd.companies,
    pd.cast_count,
    CASE
        WHEN pd.production_year = EXTRACT(YEAR FROM DATE '2024-10-01') THEN 'Released This Year'
        WHEN pd.production_year = EXTRACT(YEAR FROM DATE '2024-10-01') - 1 THEN 'Released Last Year'
        ELSE 'Older'
    END AS release_status,
    CASE
        WHEN pd.current_month BETWEEN 6 AND 8 THEN 'Summer Release'
        ELSE 'Non-Summer Release'
    END AS seasonal_release
FROM
    ProductionDetails pd
ORDER BY
    pd.production_year DESC,
    pd.cast_count DESC;
