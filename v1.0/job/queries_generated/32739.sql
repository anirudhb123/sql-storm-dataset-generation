WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        mt.episode_of_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        mo.id,
        mo.title,
        mo.production_year,
        mh.level + 1,
        mo.episode_of_id
    FROM 
        aka_title mo
    INNER JOIN 
        MovieHierarchy mh ON mo.episode_of_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COALESCE(c.role_id, rt.role) AS role,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    SUM(mi.info LIKE '%award%') AS award_count,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY m.production_year DESC) AS movie_rank
FROM 
    aka_name a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
INNER JOIN 
    MovieHierarchy m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    role_type rt ON c.role_id = rt.id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'award')
GROUP BY 
    a.name, m.title, m.production_year, c.role_id, rt.role
HAVING 
    COUNT(DISTINCT kc.keyword) > 3
ORDER BY 
    movie_rank, actor_name;
