
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        mt.episode_of_id,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year = 2023 
    UNION ALL
    SELECT 
        mh.movie_id,
        m.title,
        m.production_year,
        m.episode_of_id,
        mh.level + 1
    FROM MovieHierarchy mh
    JOIN aka_title m ON m.id = mh.episode_of_id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    ct.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_notes_count,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY at.production_year DESC) AS movie_rank,
    STRING_AGG(DISTINCT ki.keyword, ', ') AS keywords,
    COALESCE(pi.info, 'No info available') AS person_info
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON at.id = ci.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = ci.movie_id
LEFT JOIN 
    company_type ct ON ct.id = mc.company_type_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = ci.movie_id
LEFT JOIN 
    keyword ki ON ki.id = mk.keyword_id
LEFT JOIN 
    person_info pi ON pi.person_id = ak.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
WHERE 
    ak.name IS NOT NULL
    AND at.production_year > 2000
    AND at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'Feature Film')
GROUP BY 
    ak.name, at.title, at.production_year, ct.kind, pi.info, ak.person_id
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    movie_rank, at.production_year DESC;
