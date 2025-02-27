WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        mh.level < 3
)
SELECT 
    h.title AS Movie_Title,
    h.production_year AS Production_Year,
    h.level AS Hierarchy_Level,
    p.name AS Person_Name,
    COUNT(DISTINCT mc.company_id) AS Company_Count,
    AVG(CASE WHEN ri.role IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY h.movie_id) AS Has_Roles_Avg
FROM 
    movie_hierarchy h
LEFT JOIN 
    complete_cast cc ON h.movie_id = cc.movie_id
LEFT JOIN 
    aka_name p ON cc.subject_id = p.person_id
LEFT JOIN 
    movie_companies mc ON h.movie_id = mc.movie_id
LEFT JOIN 
    role_type ri ON cc.role_id = ri.id
WHERE 
    h.level <= 2
GROUP BY 
    h.movie_id, h.title, h.production_year, h.level, p.name
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    h.production_year DESC, h.level ASC, Movie_Title;
