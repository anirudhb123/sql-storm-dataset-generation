WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ml.linked_movie_id,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    WHERE 
        mh.depth < 3  
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT ak.id) AS num_actors,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    SUM(CASE 
            WHEN c.nr_order IS NOT NULL THEN 1 
            ELSE 0 
        END) AS cast_count,
    ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ak.id) DESC) AS rank
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.person_id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    aka_title at ON mh.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    ak.name, at.title, at.production_year
HAVING 
    COUNT(DISTINCT ak.id) > 0 
ORDER BY 
    at.production_year DESC, 
    num_actors DESC;