WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        mc.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link mc
    JOIN 
        aka_title at ON mc.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mc.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    m.title AS movie_title,
    MAX(mh.level) AS hierarchy_level,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_roles
FROM 
    cast_info c
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
JOIN 
    name p ON ak.id = p.id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, m.title
HAVING 
    COUNT(DISTINCT mk.keyword) > 5
ORDER BY 
    hierarchy_level DESC, actor_name;
