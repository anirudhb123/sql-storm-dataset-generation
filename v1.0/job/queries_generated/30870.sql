WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS hierarchy_level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        ml.linked_movie_id AS linked_title,
        mt.production_year,
        mh.hierarchy_level + 1
    FROM 
        movie_link AS ml
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title AS mt ON ml.linked_movie_id = mt.id
),
role_distribution AS (
    SELECT 
        ci.role_id,
        rt.role,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info AS ci
    JOIN 
        role_type AS rt ON ci.role_id = rt.id
    GROUP BY 
        ci.role_id, rt.role
)
SELECT 
    ak.name AS actor_name,
    mv.title AS movie_title,
    mv.production_year,
    COALESCE(rd.actor_count, 0) AS role_count,
    STRING_AGG(key.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY mv.production_year DESC) AS actor_movie_rank
FROM 
    aka_name AS ak
JOIN 
    cast_info AS ci ON ak.person_id = ci.person_id
JOIN 
    aka_title AS mv ON ci.movie_id = mv.id
LEFT JOIN 
    role_distribution AS rd ON ci.role_id = rd.role_id
LEFT JOIN 
    movie_keyword AS mk ON mv.id = mk.movie_id
LEFT JOIN 
    keyword AS key ON mk.keyword_id = key.id
JOIN 
    movie_hierarchy AS mh ON mv.id = mh.movie_id
WHERE 
    mv.production_year >= 2000
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, mv.title, mv.production_year, rd.actor_count
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 0
ORDER BY 
    actor_movie_rank, mv.production_year DESC;
