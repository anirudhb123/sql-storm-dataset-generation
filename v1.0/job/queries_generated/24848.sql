WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.episode_of_id,
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
        at.episode_of_id,
        level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id 
    WHERE 
        mh.level < 3  -- Limiting the hierarchy depth to avoid infinite recursion
)

SELECT 
    COALESCE(a.name, n.name) AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
    COUNT(DISTINCT ci.role_id) AS role_count,
    SUM(CASE WHEN ci.note ILIKE '%lead%' THEN 1 ELSE 0 END) AS lead_roles,
    MAX(CASE WHEN ci.nr_order IS NULL THEN 1 ELSE 0 END) AS has_null_order
FROM 
    movie_hierarchy mt
LEFT JOIN 
    cast_info ci ON mt.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
FULL OUTER JOIN 
    name n ON ci.person_id = n.imdb_id
LEFT JOIN 
    movie_keyword mk ON mt.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    (mt.kind_id IS NOT NULL AND mt.title IS NOT NULL)
    OR (a.id IS NULL AND n.id IS NULL)
GROUP BY 
    mt.title, mt.production_year, actor_name
HAVING 
    COUNT(DISTINCT ci.role_id) > 0
ORDER BY 
    production_year DESC, role_count DESC;

-- The query creates a recursive common table expression (CTE) to track hierarchical relationships in movie links. 
-- It aggregates actor names and counts roles while managing NULL cases and filtering based on movie kind.
