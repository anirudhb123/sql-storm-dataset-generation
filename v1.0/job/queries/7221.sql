WITH actor_movie_info AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year AS movie_year,
        r.role AS role_name,
        c.id AS company_id,
        cn.name AS company_name,
        k.keyword AS movie_keyword
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        title t ON c.movie_id = t.id
    JOIN
        role_type r ON c.role_id = r.id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
        AND cn.country_code = 'USA'
),
aggregated_info AS (
    SELECT
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM
        actor_movie_info
    GROUP BY
        actor_name
)
SELECT
    actor_name,
    movie_count,
    keywords
FROM
    aggregated_info
ORDER BY
    movie_count DESC
LIMIT 10;
