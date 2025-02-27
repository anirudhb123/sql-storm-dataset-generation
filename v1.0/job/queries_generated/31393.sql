WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ARRAY[mt.title] AS title_path,
        1 AS depth
    FROM 
        aka_title AS mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
  
    SELECT 
        me.id AS movie_id,
        me.title,
        me.production_year,
        mh.title_path || me.title,
        mh.depth + 1
    FROM 
        aka_title AS me
    JOIN 
        movie_hierarchy AS mh ON me.episode_of_id = mh.movie_id
)

SELECT 
    CONCAT(mh.title, ' (', mh.production_year, ')') AS full_movie_title,
    mh.depth,
    COALESCE(SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_roles,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
FROM 
    movie_hierarchy AS mh
LEFT JOIN 
    complete_cast AS cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info AS ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name AS ak ON ak.person_id = ci.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.depth
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    mh.depth DESC, mh.production_year DESC;
