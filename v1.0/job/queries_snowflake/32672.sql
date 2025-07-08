
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = 2020

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON mt.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        LISTAGG(a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    GROUP BY 
        ci.movie_id
),
active_movies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        cd.total_cast,
        cd.cast_names
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_details cd ON cd.movie_id = mh.movie_id
    WHERE 
        mh.level = 1
)
SELECT 
    am.movie_id,
    am.movie_title,
    am.production_year,
    COALESCE(am.total_cast, 0) AS total_cast,
    COALESCE(am.cast_names, 'No cast information') AS cast_names,
    CASE 
        WHEN am.production_year IS NOT NULL AND am.production_year > 2010 THEN 'Recent'
        ELSE 'Classic'
    END AS movie_age_category
FROM 
    active_movies am
LEFT JOIN 
    movie_info mi ON mi.movie_id = am.movie_id AND mi.note IS NULL
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = am.movie_id
WHERE 
    am.total_cast IS NOT NULL
ORDER BY 
    am.production_year DESC, 
    am.total_cast DESC
LIMIT 100;
