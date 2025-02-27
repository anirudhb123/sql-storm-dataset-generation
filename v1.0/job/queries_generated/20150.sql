WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS hierarchy_level,
        CAST(mt.title AS VARCHAR(255)) AS hierarchy_path
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.hierarchy_level + 1,
        CAST(mh.hierarchy_path || ' > ' || m.title AS VARCHAR(255))
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON m.id = ml.linked_movie_id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    a.production_year,
    COUNT(DISTINCT c.person_id) AS co_actor_count,
    ARRAY_AGG(DISTINCT k.keyword) FILTER (WHERE k.keyword IS NOT NULL) AS associated_keywords,
    MAX(mh.hierarchy_level) AS max_hierarchy_level,
    MIN(mh.hierarchy_level) AS min_hierarchy_level,
    STRING_AGG(DISTINCT mh.hierarchy_path, ' -> ') AS full_hierarchy_paths,
    CASE 
        WHEN a.production_year IS NULL THEN 'Unknown Year'
        WHEN a.production_year < 2000 THEN 'Before 2000'
        ELSE '2000 or Later'
    END AS year_category,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank
FROM aka_name ak
JOIN cast_info c ON ak.person_id = c.person_id
JOIN aka_title at ON c.movie_id = at.id
JOIN movie_info mi ON at.id = mi.movie_id
LEFT JOIN movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_hierarchy mh ON at.id = mh.movie_id
GROUP BY ak.name, at.title, a.production_year
HAVING COUNT(DISTINCT c.person_id) > 1
AND MIN(mh.hierarchy_level) < 3
ORDER BY actor_rank, co_actor_count DESC
LIMIT 50;
