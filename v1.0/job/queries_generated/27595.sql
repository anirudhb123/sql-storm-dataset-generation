WITH popular_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),

highly_rated_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT mi.info) AS info_count
    FROM 
        title m
    JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%rating%')
    GROUP BY 
        m.id
    HAVING 
        COUNT(DISTINCT mi.info) > 1
),

final_results AS (
    SELECT 
        pm.movie_id,
        pm.title,
        pm.cast_count,
        ARRAY_TO_STRING(pm.actor_names, ', ') AS actor_list,
        hrm.info_count AS rating_count
    FROM 
        popular_movies pm
    LEFT JOIN 
        highly_rated_movies hrm ON pm.movie_id = hrm.movie_id
)

SELECT 
    fr.movie_id,
    fr.title,
    fr.cast_count,
    fr.actor_list,
    COALESCE(fr.rating_count, 0) AS rating_count
FROM 
    final_results fr
ORDER BY 
    fr.cast_count DESC, fr.rating_count DESC;
