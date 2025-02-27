WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title,
        1 AS level 
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id, 
        mt.title AS movie_title,
        mh.level + 1 AS level 
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.production_year >= 2000
)

SELECT 
    ah.name AS actor_name,
    mt.movie_title,
    mt.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    MAX(pi.info) AS nationality_info,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY mt.id) AS note_presence_ratio,
    STRING_AGG(DISTINCT cct.kind, ', ') AS company_kinds
FROM 
    aka_name ah
JOIN 
    cast_info ci ON ah.person_id = ci.person_id
JOIN 
    MovieHierarchy mt ON ci.movie_id = mt.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON mt.movie_id = mc.movie_id
LEFT JOIN 
    company_type cct ON mc.company_type_id = cct.id
LEFT JOIN 
    person_info pi ON ah.person_id = pi.person_id AND pi.info_type_id = 
        (SELECT id FROM info_type WHERE info = 'nationality')
WHERE 
    ah.name IS NOT NULL
GROUP BY 
    ah.name, mt.movie_title, mt.production_year
HAVING 
    COUNT(DISTINCT kc.keyword) > 2 
ORDER BY 
    mt.production_year DESC, actor_name;
