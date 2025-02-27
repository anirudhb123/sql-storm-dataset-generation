
WITH actor_movie_count AS (
    SELECT
        ka.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM
        aka_name ka
    JOIN
        cast_info c ON ka.person_id = c.person_id
    GROUP BY
        ka.person_id
),
movie_info_details AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN
        company_name c ON mc.company_id = c.id
    GROUP BY
        m.id, m.title, m.production_year
),
top_actors AS (
    SELECT
        a.id,
        a.name,
        ac.movie_count
    FROM
        aka_name a
    JOIN
        actor_movie_count ac ON a.person_id = ac.person_id
    WHERE
        ac.movie_count >= 5
    ORDER BY
        ac.movie_count DESC
    LIMIT 10
)
SELECT
    ma.title,
    ma.production_year,
    ta.name AS top_actor,
    ma.keywords,
    ma.companies
FROM
    movie_info_details ma
JOIN
    cast_info ci ON ma.movie_id = ci.movie_id
JOIN 
    top_actors ta ON ci.person_id = ta.id
ORDER BY
    ma.production_year DESC, ma.title;
