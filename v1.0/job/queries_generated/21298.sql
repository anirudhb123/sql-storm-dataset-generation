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
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COALESCE(NULLIF(rt.role, ''), 'Unknown Role') AS role,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT cc.id) OVER (PARTITION BY m.id) AS total_cast,
    CASE 
        WHEN m.production_year < 2000 THEN 'Classic'
        ELSE 'Modern'
    END AS era,
    COUNT(DISTINCT ml.linked_movie_id) FILTER (WHERE ml.linked_movie_id IS NOT NULL) AS linked_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    movie_hierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    movie_link ml ON m.movie_id = ml.movie_id
WHERE 
    a.name IS NOT NULL 
    AND (m.production_year IS NOT NULL OR m.title LIKE '%_2023%')
GROUP BY 
    a.name, m.id, rt.role, m.title, m.production_year
HAVING 
    COUNT(DISTINCT k.id) >= 2 
    OR COUNT(DISTINCT cc.id) >= 5
ORDER BY 
    m.production_year DESC, total_cast DESC, actor_name;

