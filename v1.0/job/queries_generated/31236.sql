WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, 
           m.title, 
           COALESCE(m.production_year, 1900) AS production_year, 
           1 AS level
    FROM aka_title m
    WHERE m.production_year IS NOT NULL

    UNION ALL

    SELECT m.id, 
           m.title,
           m.production_year,
           mh.level + 1
    FROM aka_title m
    INNER JOIN MovieHierarchy mh ON m.episode_of_id = mh.movie_id
    WHERE mh.level < 5
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT c.role_id) AS total_roles,
    STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords,
    AVG(pi.info_type_id) FILTER (WHERE pi.info_type_id IS NOT NULL) AS avg_info_type_id,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY COUNT(DISTINCT c.role_id) DESC) AS role_rank
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword ON mk.keyword_id = keyword.id
LEFT JOIN 
    person_info pi ON pi.person_id = a.person_id
JOIN 
    MovieHierarchy mh ON t.id = mh.movie_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    total_roles > 0
ORDER BY 
    role_rank, a.name;
