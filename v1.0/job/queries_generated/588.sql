WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_title,
        COUNT(c.person_id) OVER (PARTITION BY m.id) AS total_cast
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year IS NOT NULL
),
actor_info AS (
    SELECT 
        a.person_id,
        a.name,
        a.id AS aka_id,
        COUNT(DISTINCT ci.movie_id) AS num_movies,
        STRING_AGG(DISTINCT at.title, ', ') AS movie_titles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
    GROUP BY 
        a.person_id, a.name, a.id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.rank_title,
    ai.name AS actor_name,
    ai.num_movies,
    CASE 
        WHEN ai.num_movies IS NULL THEN 'No other movies'
        ELSE ai.movie_titles
    END AS featured_movies
FROM 
    ranked_movies rm
FULL OUTER JOIN 
    actor_info ai ON rm.movie_id = ai.movie_id
WHERE 
    (rm.total_cast IS NOT NULL AND rm.total_cast > 0)
    OR (ai.num_movies >= 3)
ORDER BY 
    rm.production_year DESC, rm.rank_title;
