WITH ranked_movies AS (
    SELECT
        a.title,
        a.production_year,
        c.name AS company_name,
        c.country_code,
        r.role AS role_type,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank
    FROM
        aka_title a
    JOIN
        movie_companies mc ON a.id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        cast_info ci ON a.id = ci.movie_id
    JOIN
        role_type r ON ci.role_id = r.id
    WHERE
        a.production_year IS NOT NULL
),

movie_keywords AS (
    SELECT
        m.id AS movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM
        aka_title m
    JOIN
        movie_keyword mk ON m.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
)

SELECT
    rm.rank,
    rm.title,
    rm.production_year,
    rm.company_name,
    rm.country_code,
    rm.role_type,
    STRING_AGG(mk.keyword, ', ') AS keywords
FROM
    ranked_movies rm
LEFT JOIN
    movie_keywords mk ON rm.title = mk.movie_id
WHERE
    rm.rank <= 10
GROUP BY
    rm.rank, rm.title, rm.production_year, rm.company_name, rm.country_code, rm.role_type
ORDER BY
    rm.rank;

