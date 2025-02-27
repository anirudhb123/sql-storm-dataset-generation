WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.production_year > 2000
),

TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rn
    FROM 
        MovieHierarchy mh
)

SELECT 
    mn.name AS director_name,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    AVG(CASE 
        WHEN ai.kind_id IS NOT NULL THEN 1 
        ELSE 0 
    END) AS avg_main_roles,
    STRING_AGG(DISTINCT mt.title, ', ') AS connected_movie_titles,
    COALESCE(SUM(mi.info IS NOT NULL::int), 0) AS total_infos
FROM 
    cast_info c
JOIN 
    aka_name mn ON c.person_id = mn.person_id
LEFT JOIN 
    complete_cast cc ON c.movie_id = cc.movie_id
LEFT JOIN 
    movie_info mi ON c.movie_id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')
LEFT JOIN 
    TopMovies mt ON c.movie_id = mt.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = c.movie_id
LEFT JOIN 
    comp_cast_type ai ON ai.id = c.person_role_id
WHERE 
    c.nr_order < 5
GROUP BY 
    mn.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 1
ORDER BY 
    total_movies DESC, director_name;
