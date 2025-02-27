WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL AS parent_movie_id
    FROM title mt
    WHERE mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1,
        mh.movie_id AS parent_movie_id
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN title t ON ml.linked_movie_id = t.id
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    COALESCE(c.name, 'Unknown') AS company_name,
    k.keyword AS movie_keyword,
    RANK() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank,
    COUNT(DISTINCT ca.person_id) OVER (PARTITION BY m.id) AS total_cast_members,
    STRING_AGG(DISTINCT CONCAT(a.name, ' (', rt.role, ')'), ', ') AS cast_details
FROM MovieHierarchy m
LEFT JOIN movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN company_name c ON mc.company_id = c.id
LEFT JOIN movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN cast_info ca ON cc.subject_id = ca.person_id
LEFT JOIN role_type rt ON ca.role_id = rt.id
LEFT JOIN aka_name a ON ca.person_id = a.person_id
WHERE m.level < 3
GROUP BY m.movie_id, m.title, m.production_year, c.name, k.keyword
ORDER BY m.production_year DESC, title_rank
LIMIT 100;
