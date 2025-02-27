WITH ranked_movies AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.id = c.movie_id
    GROUP BY
        a.id
),
company_movies AS (
    SELECT
        m.movie_id,
        c.name AS company_name,
        co.kind AS company_type
    FROM
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type co ON m.company_type_id = co.id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    rm.title,
    rm.production_year,
    rm.cast_count,
    cm.company_name,
    cm.company_type,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM
    ranked_movies rm
LEFT JOIN
    company_movies cm ON rm.title = cm.movie_id
LEFT JOIN
    movie_keywords mk ON rm.title = mk.movie_id
WHERE
    (rm.rank <= 10 OR rm.cast_count > 5)
    AND (rm.production_year IS NOT NULL)
ORDER BY
    rm.production_year, rm.cast_count DESC;
