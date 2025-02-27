WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
)

, actor_movie_counts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS linked_movie_count,
    amc.movie_count,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    MAX(mh.level) AS max_level
FROM 
    aka_name a
LEFT JOIN 
    actor_movie_counts amc ON a.person_id = amc.person_id
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name, amc.movie_count
HAVING 
    COUNT(DISTINCT mh.movie_id) > 0 
    OR amc.movie_count IS NOT NULL
ORDER BY 
    linked_movie_count DESC, max_level DESC
LIMIT 100;

SELECT 
    'Summary' AS report_type,
    COUNT(DISTINCT a.id) AS total_actors,
    SUM(COALESCE(amc.movie_count, 0)) AS total_movies_participated
FROM 
    aka_name a
LEFT JOIN 
    actor_movie_counts amc ON a.person_id = amc.person_id
WHERE 
    (a.name IS NOT NULL AND a.name != '')
    AND (amc.movie_count IS NULL OR amc.movie_count > 0);
