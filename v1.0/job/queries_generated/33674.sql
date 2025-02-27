WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.production_year > 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COALESCE(STRING_AGG(DISTINCT kw.keyword, ', '), 'No keywords') AS keywords,
    COUNT(DISTINCT cc.id) AS total_casts,
    AVG(mr.rating) AS average_rating
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    complete_cast cc ON mt.id = cc.movie_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mt.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating' LIMIT 1)
LEFT JOIN 
    (SELECT movie_id, AVG(CAST(info AS FLOAT)) AS rating
     FROM movie_info 
     WHERE info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Rating%')
     GROUP BY movie_id) mr ON mt.id = mr.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT ci.id) > 2
ORDER BY 
    average_rating DESC, mt.production_year ASC;
