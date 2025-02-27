WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt 
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    INNER JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    ch.name AS character_name,
    ak.name AS aka_name,
    mt.movie_title,
    mt.production_year,
    COUNT(DISTINCT ci.id) AS number_of_cast_members,
    MAX(CASE WHEN ci.nr_order = 1 THEN ak.name END) AS lead_actor,
    AVG(CASE WHEN mt.production_year > 2000 THEN 1 END) AS average_post_2000_movies
FROM 
    movie_hierarchy mt
LEFT JOIN 
    cast_info ci ON mt.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    char_name ch ON ak.person_id = ch.imdb_id
WHERE 
    mt.production_year IS NOT NULL
GROUP BY 
    ch.name, ak.name, mt.movie_title, mt.production_year
HAVING 
    COUNT(DISTINCT ci.id) > 1 AND
    SUM(CASE WHEN mt.production_year < 2000 THEN 1 ELSE 0 END) = 0
ORDER BY 
    mt.production_year DESC, number_of_cast_members DESC
LIMIT 100;


