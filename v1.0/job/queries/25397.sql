
WITH movie_summary AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliases,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    LEFT JOIN
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword kw ON kw.id = mk.keyword_id
    GROUP BY
        t.id, t.title, t.production_year
),
top_years AS (
    SELECT
        production_year,
        COUNT(movie_id) AS movie_count
    FROM
        movie_summary
    GROUP BY
        production_year
    ORDER BY
        movie_count DESC
    LIMIT 5
)
SELECT
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.cast_count,
    ms.aliases,
    ms.keywords
FROM
    movie_summary ms
JOIN 
    top_years ty ON ms.production_year = ty.production_year
ORDER BY
    ms.production_year DESC, ms.cast_count DESC;
