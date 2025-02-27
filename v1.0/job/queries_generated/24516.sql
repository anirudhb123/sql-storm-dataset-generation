WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, 
           COALESCE(mt.production_year::text, 'Unknown Year') AS production_year,
           0 AS depth
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT m.id AS movie_id, m.title, 
           COALESCE(m.production_year::text, 'Unknown Year') AS production_year,
           mh.depth + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.movie_id
    JOIN movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    COALESCE(ak.name, 'Unknown Actor') AS actor_name,
    ci.note AS role_note,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    string_agg(DISTINCT kc.keyword, ', ') AS keywords
FROM movie_hierarchy m
LEFT OUTER JOIN cast_info ci ON ci.movie_id = m.movie_id
LEFT OUTER JOIN aka_name ak ON ak.person_id = ci.person_id
LEFT OUTER JOIN movie_keyword mk ON mk.movie_id = m.movie_id
LEFT OUTER JOIN keyword kc ON kc.id = mk.keyword_id
WHERE m.depth < 5
GROUP BY m.movie_id, m.title, m.production_year, ak.name, ci.note
HAVING COUNT(DISTINCT kc.keyword) > 0
ORDER BY keyword_count DESC, m.production_year DESC
LIMIT 100;

WITH company_roles AS (
    SELECT mc.movie_id, ct.kind AS company_kind, COUNT(*) AS company_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, ct.kind
    HAVING COUNT(*) > 1
)

SELECT 
    m.title,
    c.company_kind,
    cr.company_count
FROM aka_title m
JOIN company_roles cr ON m.id = cr.movie_id
LEFT JOIN company_name c ON c.id IN (SELECT company_id FROM movie_companies WHERE movie_id = m.id)
WHERE c.country_code IS NULL OR LENGTH(c.country_code) = 0
ORDER BY cr.company_count DESC, m.title;
