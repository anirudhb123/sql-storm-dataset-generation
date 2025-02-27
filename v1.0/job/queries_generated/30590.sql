WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        m.movie_id AS parent_movie_id,
        1 AS level
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN movie_info mi ON t.id = mi.movie_id
    JOIN company_name c ON mc.company_id = c.id
    WHERE c.country_code = 'USA' 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
        AND mi.info IS NOT NULL AND mi.info <> ''
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        m.title,
        m.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM movie_hierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN title m ON ml.linked_movie_id = m.id
)

SELECT 
    name.name AS actor_name,
    t.title AS movie_title,
    b.year AS release_year,
    COUNT(DISTINCT cc.movie_id) AS co_starring_movies,
    AVG(CASE WHEN t.production_year IS NULL THEN NULL ELSE t.production_year END) OVER (PARTITION BY name.name) AS avg_production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM aka_name name
JOIN cast_info ci ON name.person_id = ci.person_id
JOIN title t ON ci.movie_id = t.id
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN complete_cast cc ON t.id = cc.movie_id
LEFT JOIN movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND name.name IS NOT NULL
GROUP BY 
    name.name, 
    t.title,
    b.year
ORDER BY 
    co_starring_movies DESC,
    actor_name ASC;
