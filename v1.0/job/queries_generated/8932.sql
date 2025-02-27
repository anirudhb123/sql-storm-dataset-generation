WITH movie_data AS (
    SELECT
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        r.role AS actor_role
    FROM
        aka_title t
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        movie_keyword mw ON t.id = mw.movie_id
    JOIN
        keyword k ON mw.keyword_id = k.id
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        role_type r ON ci.role_id = r.id
    WHERE
        t.production_year >= 2000
        AND k.keyword IS NOT NULL
        AND c.country_code = 'USA'
)
SELECT
    movie_title,
    production_year,
    COUNT(DISTINCT actor_name) AS actor_count,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
FROM
    movie_data
GROUP BY
    movie_title, production_year
HAVING
    COUNT(DISTINCT actor_name) > 1
ORDER BY
    production_year DESC, actor_count DESC;
