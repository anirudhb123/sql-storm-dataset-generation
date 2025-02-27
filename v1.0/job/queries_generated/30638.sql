WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        0 AS level,
        mt.production_year,
        NULL AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        (SELECT title FROM aka_title WHERE id = ml.linked_movie_id) AS movie_title,
        mh.level + 1,
        (SELECT production_year FROM aka_title WHERE id = ml.linked_movie_id) AS production_year,
        mh.movie_id AS parent_movie_id
    FROM 
        movie_link ml
    INNER JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(CASE WHEN p.info_type_id = (SELECT id FROM info_type WHERE info = 'Birthdate') THEN CAST(p.info AS DATE) END) AS average_birthdate,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY at.production_year DESC) AS movie_rank,
    COALESCE(COUNT(mc.company_id), 0) AS production_company_count 
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    aka_title at ON c.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    person_info p ON ak.person_id = p.person_id
LEFT JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
WHERE 
    at.production_year IS NOT NULL
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, at.title, at.production_year
HAVING 
    COUNT(DISTINCT kc.keyword) > 2
ORDER BY 
    actor_name, movie_rank;
