WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT
    ak.name AS actor_name,
    COUNT(DISTINCT ch.id) AS character_count,
    STRING_AGG(DISTINCT kh.keyword, ', ') AS keywords,
    AVG(mh.production_year) AS avg_production_year,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS rank
FROM
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    keyword kh ON mk.keyword_id = kh.id
LEFT JOIN
    char_name ch ON ci.role_id = ch.id
WHERE 
    mh.level IS NOT NULL
GROUP BY
    ak.id
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY
    rank
LIMIT 10;
