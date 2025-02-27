WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM
        aka_title t
    WHERE
        t.production_year BETWEEN 2000 AND 2020
),
top_cast AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        c.nr_order <= 5
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
    rm.movie_id, 
    rm.title, 
    rm.production_year,
    GROUP_CONCAT(DISTINCT tc.actor_name ORDER BY tc.actor_rank) AS top_actors,
    mk.keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    top_cast tc ON rm.movie_id = tc.movie_id
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rn <= 10
GROUP BY 
    rm.movie_id, rm.title, rm.production_year
ORDER BY 
    rm.production_year DESC, rm.movie_id;
