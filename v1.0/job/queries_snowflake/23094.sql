
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_summary AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS num_actors,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
keyword_info AS (
    SELECT 
        m.movie_id, 
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    cs.num_actors,
    cs.actor_names,
    ki.keywords,
    CASE
        WHEN rm.year_rank < 5 THEN 'Top 5 of the Year'
        ELSE 'Not Top 5'
    END AS popularity_class
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_summary cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    keyword_info ki ON rm.movie_id = ki.movie_id
WHERE 
    (rm.production_year BETWEEN 2000 AND 2023)
    AND (cs.num_actors IS NOT NULL OR ki.keywords IS NOT NULL)
ORDER BY 
    rm.year_rank, cs.num_actors DESC NULLS LAST
LIMIT 50;
