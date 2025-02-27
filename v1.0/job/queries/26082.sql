
WITH movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
        STRING_AGG(DISTINCT c.name, ',') AS companies,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name c ON mc.company_id = c.id
    LEFT JOIN
        cast_info ca ON t.id = ca.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.companies,
        md.cast_count,
        RANK() OVER (ORDER BY md.cast_count DESC) AS rank
    FROM
        movie_details md
)
SELECT
    tm.rank,
    tm.title,
    tm.production_year,
    tm.keywords,
    tm.companies,
    tm.cast_count
FROM
    top_movies tm
WHERE
    tm.rank <= 10
ORDER BY
    tm.rank;
