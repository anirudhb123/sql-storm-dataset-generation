
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT ch.movie_id) AS total_movies,
    SUM(CASE WHEN ch.role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_count,
    STRING_AGG(DISTINCT at.title || ' (' || at.production_year || ')', ', ') AS movies_list,
    COALESCE(MAX(n.gender), 'Unknown') AS gender,
    AVG(mh.level) AS avg_hierarchy_level,
    RANK() OVER (PARTITION BY COALESCE(n.gender, 'Unknown') ORDER BY COUNT(DISTINCT ch.movie_id) DESC) AS rank_by_gender
FROM 
    cast_info ch
JOIN 
    aka_name ak ON ch.person_id = ak.person_id
LEFT JOIN 
    movie_hierarchy mh ON ch.movie_id = mh.movie_id
LEFT JOIN 
    name n ON ak.name = n.name
JOIN 
    aka_title at ON ch.movie_id = at.id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
    AND at.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
GROUP BY 
    ak.name, n.gender
HAVING 
    COUNT(DISTINCT ch.movie_id) > 5
ORDER BY 
    total_movies DESC, 
    rank_by_gender ASC;
