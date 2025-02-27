WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        mt.id AS root_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        mh.root_movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    h.root_movie_id,
    h.title AS root_movie_title,
    h.production_year AS root_movie_year,
    h.level,
    COUNT(*) OVER (PARTITION BY h.root_movie_id) AS linked_movies_count,
    STRING_AGG(DISTINCT at.title, ', ') FILTER (WHERE at.title IS NOT NULL) AS linked_movie_titles,
    COALESCE(SUM(mi.info IS NOT NULL)::INT, 0) AS info_count,
    CASE
        WHEN COUNT(DISTINCT c.id) > 0 THEN 'Has Cast'
        ELSE 'No Cast'
    END AS cast_info
FROM 
    movie_hierarchy h
LEFT JOIN 
    movie_link ml ON h.movie_id = ml.movie_id
LEFT JOIN 
    aka_title at ON ml.linked_movie_id = at.id
LEFT JOIN 
    complete_cast cc ON h.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON c.movie_id = h.movie_id
LEFT JOIN 
    movie_info mi ON h.movie_id = mi.movie_id
GROUP BY 
    h.root_movie_id, h.title, h.production_year, h.level
ORDER BY 
    h.root_movie_id, h.level, linked_movies_count DESC
LIMIT 100;
