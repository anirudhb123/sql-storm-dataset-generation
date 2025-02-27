WITH ranked_movies AS (
    SELECT
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title a
    JOIN
        cast_info c ON a.id = c.movie_id
    GROUP BY
        a.id, a.title, a.production_year
),
company_movie_count AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name co ON mc.company_id = co.id
    WHERE
        co.country_code IS NOT NULL
    GROUP BY
        mc.movie_id
),
top_movies AS (
    SELECT
        r.movie_title,
        r.production_year,
        r.cast_count,
        COALESCE(c.company_count, 0) AS company_count
    FROM
        ranked_movies r
    LEFT JOIN
        company_movie_count c ON r.production_year = c.movie_id
    WHERE
        r.rank <= 10
)
SELECT
    movie_title,
    production_year,
    cast_count,
    company_count,
    CASE 
        WHEN cast_count > company_count THEN 'More Cast Than Companies'
        WHEN cast_count < company_count THEN 'More Companies Than Cast'
        ELSE 'Equal Cast and Companies'
    END AS cast_vs_company
FROM
    top_movies
WHERE
    production_year IS NOT NULL
ORDER BY
    production_year DESC, cast_count DESC;
