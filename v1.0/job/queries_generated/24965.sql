WITH RECURSIVE movie_chain AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        a.title AS movie_title,
        mc.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        movie_chain mc ON mc.movie_id = ml.movie_id
    WHERE 
        mc.depth < 5
)

SELECT 
    ac.name AS actor_name, 
    at.title AS movie_title,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    sum(CASE WHEN pi.info_type_id = 1 THEN 1 ELSE 0 END) AS total_person_info,
    MAX(CASE WHEN ak.name IS NULL THEN 'Unknown' ELSE ak.name END) AS aka_name,
    ROW_NUMBER() OVER (PARTITION BY ac.name ORDER BY COUNT(DISTINCT mk.keyword) DESC) AS rank
FROM 
    cast_info c
JOIN 
    aka_name ac ON c.person_id = ac.person_id
JOIN 
    aka_title at ON c.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id 
LEFT JOIN 
    person_info pi ON ac.person_id = pi.person_id
LEFT JOIN 
    movie_chain mc ON mc.movie_id = at.id
LEFT JOIN 
    aka_name ak ON mc.movie_id = ak.person_id AND ak.name IS NOT NULL 
WHERE 
    at.production_year BETWEEN 2000 AND 2023
GROUP BY 
    ac.name, at.title
HAVING 
    COUNT(DISTINCT mk.keyword) > 0
    AND COUNT(DISTINCT pi.info) > 1
ORDER BY 
    keyword_count DESC, actor_name ASC;
