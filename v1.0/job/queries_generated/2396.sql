WITH ranked_movies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aliases,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info cc ON mt.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.person_id = ak.person_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
popular_actors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(cc.movie_id) AS movie_count 
    FROM 
        aka_name ak
    JOIN 
        cast_info cc ON ak.person_id = cc.person_id
    GROUP BY 
        ak.id, ak.name
    HAVING 
        COUNT(cc.movie_id) > 5
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.aliases,
    rm.cast_count,
    pa.actor_name,
    pa.movie_count
FROM 
    ranked_movies rm
LEFT JOIN 
    popular_actors pa ON pa.movie_count = rm.cast_count
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC
UNION
SELECT 
    DISTINCT 'N/A' AS movie_title,
    NULL AS production_year,
    ARRAY[NULL] AS aliases,
    NULL AS cast_count,
    pa.actor_name,
    pa.movie_count
FROM 
    popular_actors pa
WHERE 
    pa.movie_count < 3
ORDER BY 
    movie_count DESC;
