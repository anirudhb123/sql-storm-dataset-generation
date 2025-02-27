
WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 1
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
),
detailed_movies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COALESCE(k.keywords, 'No Keywords') AS keywords,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rn
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ca ON at.id = ca.movie_id
    LEFT JOIN 
        movie_keywords k ON at.id = k.movie_id
    GROUP BY 
        at.id, at.title, at.production_year, k.keywords
)
SELECT 
    dm.title,
    dm.production_year,
    dm.cast_count,
    ah.movie_count AS actor_movie_count,
    ah.person_id
FROM 
    detailed_movies dm
LEFT JOIN 
    actor_hierarchy ah ON dm.cast_count = ah.movie_count
WHERE 
    dm.production_year >= 2000 AND 
    dm.rn <= 5
ORDER BY 
    dm.production_year DESC, 
    dm.cast_count DESC;
