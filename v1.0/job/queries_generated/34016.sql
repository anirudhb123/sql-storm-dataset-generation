WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        0 AS hierarchy_level
    FROM 
        aka_title mt
    WHERE 
        mt.title ILIKE '%the%'

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.hierarchy_level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    p.name AS actor_name,
    COALESCE(COUNT(DISTINCT c.movie_id), 0) AS total_movies,
    SUM(CASE WHEN mh.hierarchy_level > 0 THEN 1 ELSE 0 END) AS linked_movies,
    STRING_AGG(DISTINCT title.title, ', ') AS movie_titles,
    MAX(mh.production_year) AS latest_movie_year
FROM 
    aka_name p
LEFT JOIN 
    cast_info c ON c.person_id = p.person_id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = c.movie_id
LEFT JOIN 
    aka_title title ON title.id = c.movie_id
WHERE 
    p.name IS NOT NULL
GROUP BY 
    p.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 0 OR
    SUM(CASE WHEN mh.hierarchy_level > 0 THEN 1 ELSE 0 END) > 0
ORDER BY 
    total_movies DESC,
    latest_movie_year DESC
LIMIT 10;

WITH movie_info_agg AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info ILIKE '%budget%' THEN mi.info END) AS budget_info,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_info mi
    JOIN 
        info_type it ON it.id = mi.info_type_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mi.movie_id
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_title,
    mh.production_year,
    mia.budget_info,
    mia.keyword_count,
    ROUND(AVG(mia.keyword_count) OVER (PARTITION BY mh.production_year), 2) AS avg_keywords_per_year
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_info_agg mia ON mh.movie_id = mia.movie_id
WHERE 
    mh.production_year IS NOT NULL
ORDER BY 
    mh.production_year DESC;
