WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, 1 AS level
    FROM aka_title m
    WHERE m.production_year = (SELECT MAX(production_year) FROM aka_title)

    UNION ALL

    SELECT m.id AS movie_id, m.title, mh.level + 1
    FROM aka_title m
    JOIN movie_link ml ON ml.linked_movie_id = m.id
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    c.role_id,
    COALESCE(NULLIF(c.note, ''), 'No additional notes') AS role_notes,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY m.production_year DESC) AS movie_rank,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.person_id = a.person_id) AS total_roles,
    array_agg(DISTINCT k.keyword) AS keywords,
    (SELECT COUNT(DISTINCT mk.keyword_id) FROM movie_keyword mk WHERE mk.movie_id = m.id) AS distinct_keywords_count,
    CASE 
        WHEN a.name IS NULL THEN 'Unknown Actor'
        ELSE a.name
    END AS safe_actor_name
FROM aka_name a
LEFT JOIN cast_info c ON a.person_id = c.person_id
LEFT JOIN aka_title m ON c.movie_id = m.id
LEFT JOIN movie_keyword k ON m.id = k.movie_id
LEFT JOIN movie_companies mc ON mc.movie_id = m.id
LEFT JOIN movie_info mi ON mi.movie_id = m.id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
    AND (m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Film%'))
    AND (mc.company_id IS NULL OR mc.note IS NULL)
GROUP BY 
    a.name, m.title, m.production_year, c.role_id, c.note
HAVING 
    COUNT(DISTINCT k.keyword) > 3
ORDER BY 
    movie_rank, a.name;
