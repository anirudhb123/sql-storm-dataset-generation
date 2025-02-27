WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'series'))
    
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title a ON a.id = ml.linked_movie_id
)

SELECT 
    ak.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT mc.company_id) AS producer_count,
    SUM(CASE WHEN ki.keyword IN ('Action', 'Thriller') THEN 1 ELSE 0 END) AS action_thriller_count,
    STRING_AGG(DISTINCT ki.keyword, ', ') FILTER (WHERE ki.keyword IS NOT NULL) AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY m.production_year DESC) AS actor_movie_rank,
    COALESCE(NULLIF(m.note, ''), 'N/A') AS movie_note,
    CASE WHEN m.production_year > (SELECT AVG(production_year) FROM aka_title) THEN 'Recent' ELSE 'Old' END AS movie_age_category,
    CASE WHEN ak.surname_pcode IS NULL THEN 'Surname code unknown' ELSE ak.surname_pcode END AS surname_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    movie_hierarchy mh ON m.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND (m.note IS NULL OR m.note NOT LIKE '%documentary%')
    AND ak.id IN (SELECT DISTINCT person_id FROM person_info WHERE info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%bio%'))
GROUP BY 
    ak.name, m.title, m.production_year, m.note, ak.surname_pcode
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    actor_movie_rank, movie_title;
