WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, t.title, t.production_year, 0 AS level
    FROM aka_title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE cn.country_code = 'USA' 

    UNION ALL

    SELECT mh.movie_id, t.title, t.production_year, mh.level + 1
    FROM movie_hierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title t ON ml.linked_movie_id = t.id
)

SELECT 
    m.title,
    m.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    AVG(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS avg_null_notes,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    MAX(mh.level) AS hierarchy_level
FROM 
    movie_hierarchy mh
JOIN 
    aka_title m ON mh.movie_id = m.id
LEFT JOIN 
    cast_info ci ON m.id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    m.production_year IS NOT NULL
    AND m.production_year > 2000
    AND ak.name IS NOT NULL
GROUP BY 
    m.id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    m.production_year DESC, total_cast DESC
LIMIT 10;

