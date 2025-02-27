WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
),
movie_cast AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
popular_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(mc.total_cast, 0) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY COALESCE(mc.total_cast, 0) DESC) AS rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_cast mc ON mh.movie_id = mc.movie_id
)
SELECT 
    pm.movie_id,
    pm.title,
    pm.production_year,
    pm.total_cast
FROM 
    popular_movies pm
WHERE 
    pm.rank <= 5 AND pm.total_cast > 2
ORDER BY 
    pm.production_year DESC, 
    pm.total_cast DESC;
