WITH RECURSIVE movie_recursive AS (
    SELECT mt.id AS movie_id, 
           mt.title, 
           mt.production_year, 
           0 AS depth
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
      AND mt.production_year BETWEEN 2000 AND 2020
    
    UNION ALL
    
    SELECT mt.id, 
           mt.title, 
           mt.production_year, 
           mr.depth + 1
    FROM movie_recursive mr
    JOIN movie_link ml ON mr.movie_id = ml.movie_id 
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
    WHERE mr.depth < 3 
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    MAX(pi.info) AS highest_note,
    STRING_AGG(DISTINCT cct.kind, ', ') AS company_kinds,
    SUM(COALESCE(mc.company_type_id, 0) * 10) AS total_company_weight,
    RANK() OVER (PARTITION BY m.production_year ORDER BY SUM(COALESCE(mc.company_type_id, 0)) DESC) AS year_rank,
    CASE 
        WHEN COUNT(DISTINCT kc.keyword) > 5 THEN 'Highly Keyworded'
        WHEN COUNT(DISTINCT kc.keyword) = 0 THEN 'No Keywords'
        ELSE 'Moderately Keyworded'
    END AS keyword_status
FROM movie_recursive m
JOIN cast_info ci ON m.movie_id = ci.movie_id
JOIN aka_name a ON ci.person_id = a.person_id
LEFT JOIN movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN keyword kc ON mk.keyword_id = kc.id
LEFT JOIN movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN company_type cct ON mc.company_type_id = cct.id
LEFT JOIN person_info pi ON a.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Note' LIMIT 1)
WHERE a.name IS NOT NULL
GROUP BY a.name, m.title, m.production_year
HAVING COUNT(DISTINCT kc.keyword) > 0
   OR SUM(m.production_year) IS NULL 
ORDER BY year_rank, total_company_weight DESC;