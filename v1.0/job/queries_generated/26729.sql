WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),

popular_actors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(ci.movie_id) > 10
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
    rm.movie_title,
    rm.production_year,
    pa.actor_name,
    mk.keywords
FROM 
    ranked_movies rm
JOIN 
    popular_actors pa ON pa.movie_count > 0
JOIN 
    cast_info ci ON ci.movie_id = rm.movie_id
JOIN 
    movie_keywords mk ON mk.movie_id = rm.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, pa.movie_count DESC;
