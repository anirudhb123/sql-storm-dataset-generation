WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS depth
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        mh.depth + 1
    FROM 
        movie_link AS ml
    JOIN 
        title AS m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    mt.movie_title,
    COUNT(DISTINCT ci.id) OVER (PARTITION BY ak.name) AS total_movies,
    MAX(mh.depth) AS max_link_depth,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    MAX(person_info.info) AS personal_info
FROM 
    aka_name AS ak
JOIN 
    cast_info AS ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy AS mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword AS mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS kw ON mk.keyword_id = kw.id
LEFT JOIN 
    person_info ON ak.person_id = person_info.person_id
WHERE 
    ak.name IS NOT NULL
    AND (person_info.info IS NULL OR person_info.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography'))
GROUP BY 
    ak.name, mt.movie_title
ORDER BY 
    total_movies DESC, actor_name
LIMIT 100;

