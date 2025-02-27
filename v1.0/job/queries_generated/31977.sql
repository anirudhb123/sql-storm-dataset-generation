WITH RECURSIVE title_hierarchy AS (
    SELECT t.id AS title_id, t.title, t.production_year, t.episode_of_id,
           0 AS level
    FROM title t
    WHERE t.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT t.id AS title_id, t.title, t.production_year, t.episode_of_id,
           th.level + 1
    FROM title t
    JOIN title_hierarchy th ON t.episode_of_id = th.title_id
)

SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT c.person_id) AS actor_count,
    COUNT(DISTINCT k.keyword) FILTER (WHERE k.keyword IS NOT NULL) AS keyword_count,
    AVG(COALESCE(mo.info::float, 0)) AS avg_rating,
    MAX(CASE WHEN mo.note IS NOT NULL THEN mo.note ELSE 'No Note' END) AS movie_note,
    STRING_AGG(DISTINCT nm.name, ', ') AS company_names,
    ARRAY_AGG(DISTINCT cn.country_code) FILTER (WHERE cn.country_code IS NOT NULL) AS country_codes,
    SUM(CASE WHEN cc.kind IS NOT NULL THEN 1 ELSE 0 END) AS comp_cast_type_count
FROM title_hierarchy th
JOIN aka_title at ON th.title_id = at.movie_id
JOIN aka_name ak ON ak.person_id = at.title_id
JOIN cast_info c ON c.movie_id = th.title_id
LEFT JOIN movie_keyword mk ON mk.movie_id = th.title_id
LEFT JOIN keyword k ON k.id = mk.keyword_id
LEFT JOIN movie_info mo ON mo.movie_id = th.title_id AND mo.info_type_id = (SELECT id FROM info_type WHERE info = 'rating' LIMIT 1)
LEFT JOIN movie_companies mc ON mc.movie_id = th.title_id
LEFT JOIN company_name cn ON cn.id = mc.company_id
LEFT JOIN company_type ct ON mc.company_type_id = ct.id
LEFT JOIN comp_cast_type cc ON c.role_id = cc.id
WHERE th.production_year BETWEEN 2000 AND 2023
GROUP BY ak.name, t.title, t.production_year
ORDER BY actor_count DESC, keyword_count DESC;
