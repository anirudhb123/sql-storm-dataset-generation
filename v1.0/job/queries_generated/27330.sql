WITH popular_actors AS (
    SELECT 
        ai.person_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ai.person_id, ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
popular_titles AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        movie_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 3
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    mk.keyword_count
FROM 
    popular_actors ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title mt ON ci.movie_id = mt.id
JOIN 
    movie_keywords mk ON mt.id = mk.movie_id
WHERE 
    mk.keyword_count > 3
ORDER BY 
    ak.movie_count DESC, 
    mt.production_year DESC, 
    mk.keyword_count DESC
LIMIT 10;
