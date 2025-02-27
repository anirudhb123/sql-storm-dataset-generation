WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year BETWEEN 2000 AND 2020  -- Filter for movies within a specific range

    UNION ALL

    SELECT 
        mm.id AS movie_id,
        mm.title,
        mm.production_year,
        mm.kind_id,
        mh.level + 1
    FROM aka_title mm
    JOIN movie_link ml ON ml.linked_movie_id = mh.movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    d.level,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    SUM(mk.keyword_id) AS total_keywords,
    MAX(CASE WHEN pi.info IS NULL THEN 'No Info' ELSE pi.info END) AS info
FROM aka_name a
JOIN cast_info ci ON ci.person_id = a.person_id
JOIN aka_title at ON at.id = ci.movie_id
LEFT JOIN movie_companies mc ON mc.movie_id = at.id
LEFT JOIN company_name cn ON cn.id = mc.company_id
LEFT JOIN movie_keyword mk ON mk.movie_id = at.id
LEFT JOIN person_info pi ON pi.person_id = a.person_id
JOIN MovieHierarchy d ON d.movie_id = at.id
GROUP BY a.name, at.title, at.production_year, d.level
HAVING COUNT(DISTINCT mc.company_id) > 2  -- Only include movies with more than 2 companies
ORDER BY at.production_year ASC, actor_name DESC;
