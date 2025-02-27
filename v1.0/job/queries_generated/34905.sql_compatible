
WITH RECURSIVE TitleHierarchy AS (
    SELECT 
        mt.id AS title_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IS NOT NULL
    
    UNION ALL

    SELECT 
        mt2.id,
        mt2.title,
        mt2.production_year,
        th.level + 1
    FROM 
        aka_title mt2
    INNER JOIN 
        TitleHierarchy th ON mt2.episode_of_id = th.title_id
)

SELECT 
    p.full_name AS actor_name,
    th.title AS show_title,
    th.production_year,
    cct.kind AS cast_type,
    COUNT(DISTINCT mc.company_id) AS num_production_companies,
    AVG(mi.info_length) AS avg_info_length
FROM 
    (SELECT 
         ak.name AS full_name, 
         ak.person_id 
     FROM 
         aka_name ak) AS p
INNER JOIN 
    cast_info ci ON ci.person_id = p.person_id
INNER JOIN 
    TitleHierarchy th ON th.title_id = ci.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = th.title_id
LEFT JOIN 
    comp_cast_type cct ON cct.id = ci.person_role_id
LEFT JOIN 
    (SELECT 
         movie_id, 
         LENGTH(info) AS info_length 
     FROM 
         movie_info 
     WHERE 
         note IS NOT NULL) mi ON mi.movie_id = th.title_id
GROUP BY 
    p.full_name, th.title, th.production_year, cct.kind
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    avg_info_length DESC NULLS LAST, 
    p.full_name ASC;
