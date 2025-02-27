WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ak.name) AS actor_rank
    FROM
        aka_title t
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
),
top_movies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        STRING_AGG(m.actor_name, ', ') AS actors,
        COUNT(m.actor_name) AS total_actors
    FROM
        ranked_movies m
    WHERE
        m.actor_rank <= 3 
    GROUP BY 
        m.movie_id, m.title, m.production_year
),
keyword_count AS (
    SELECT
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_total
    FROM
        movie_keyword mk
    GROUP BY
        mk.movie_id
)
SELECT
    tm.title,
    tm.production_year,
    tm.actors,
    kc.keyword_total
FROM
    top_movies tm
LEFT JOIN
    keyword_count kc ON tm.movie_id = kc.movie_id
ORDER BY 
    tm.production_year DESC,
    kc.keyword_total DESC;