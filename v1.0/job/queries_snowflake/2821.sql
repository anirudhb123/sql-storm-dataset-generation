
WITH ranked_movies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT cc.person_id) AS actor_count,
        DENSE_RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        complete_cast mc ON mt.id = mc.movie_id
    JOIN 
        cast_info cc ON mc.subject_id = cc.id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
top_movies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        ranked_movies 
    WHERE 
        rank <= 3
),
actors_info AS (
    SELECT 
        ak.name AS actor_name,
        mt.title AS movie_title,
        mt.production_year,
        COALESCE(pi.info, 'No info available') AS additional_info
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    JOIN 
        aka_title mt ON cc.movie_id = mt.id
    LEFT JOIN 
        person_info pi ON ak.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birth date')
    WHERE 
        mt.production_year IS NOT NULL
)
SELECT 
    ai.actor_name AS actor,
    COUNT(DISTINCT ai.movie_title) AS movies_count,
    LISTAGG(DISTINCT ai.movie_title, ', ') WITHIN GROUP (ORDER BY ai.movie_title) AS movies_list,
    AVG(CASE WHEN ai.additional_info IS NULL THEN 0 ELSE 1 END) AS info_available_ratio
FROM 
    actors_info ai
JOIN 
    top_movies tm ON ai.movie_title = tm.title
GROUP BY 
    ai.actor_name
ORDER BY 
    movies_count DESC
LIMIT 10;
