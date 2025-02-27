WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM
        aka_title mt
    WHERE 
        mt.production_year = 2023

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    akn.name AS character_name,
    COUNT(DISTINCT ci.movie_id) AS total_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(CASE 
            WHEN mi.info IS NOT NULL THEN LENGTH(mi.info)
            ELSE 0 
        END) AS average_info_length,
    RANK() OVER (PARTITION BY ak.id ORDER BY total_movies DESC) AS rank_within_actor
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    char_name akn ON akn.imdb_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Plot')
WHERE 
    at.production_year BETWEEN 2000 AND 2023
    AND akn.name IS NOT NULL
GROUP BY 
    ak.name, at.title, akn.name
HAVING 
    COUNT(DISTINCT ci.movie_id) > 5
ORDER BY 
    actor_name, total_movies DESC
LIMIT 50;

-- Additional Benchmark Analytics
SELECT 
    mh.title AS movie_title,
    COUNT(DISTINCT ci.person_id) AS num_actors,
    SUM(CASE WHEN c.kind IS NOT NULL THEN 1 ELSE 0 END) AS num_types
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
GROUP BY 
    mh.title
ORDER BY 
    num_actors DESC, mh.title
LIMIT 20;

-- To analyze the NULL scenario specifically
SELECT 
    ak.name AS actor_name,
    COALESCE(NULLIF(at.production_year, 2023), 'Unknown Year') AS year,
    COUNT(DISTINCT ci.movie_id) AS total_movies
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    aka_title at ON ci.movie_id = at.id
GROUP BY 
    ak.name, at.production_year
HAVING 
    COUNT(DISTINCT ci.movie_id) > 0
ORDER BY 
    total_movies DESC
LIMIT 50;
