WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title AS mt
    WHERE 
        production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
)

SELECT 
    ak.person_id,
    ak.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(pi.info) AS avg_person_info_length,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY m.production_year DESC) AS rn
FROM 
    aka_name AS ak
JOIN 
    cast_info AS ci ON ak.person_id = ci.person_id
JOIN 
    aka_title AS m ON ci.movie_id = m.id
LEFT JOIN 
    movie_companies AS mc ON m.id = mc.movie_id
LEFT JOIN 
    movie_keyword AS mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword AS kw ON mk.keyword_id = kw.id
LEFT JOIN 
    person_info AS pi ON ak.person_id = pi.person_id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
    AND (m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series')))
    AND (ci.note IS NULL OR ci.note != 'uncredited') 
    AND ak.name IS NOT NULL
GROUP BY 
    ak.person_id, ak.name, m.title, m.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) >= 3
ORDER BY 
    m.production_year DESC, ak.person_id;
