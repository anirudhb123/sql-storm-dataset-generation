WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        m.id AS linked_movie_id,
        ml.link_type_id
    FROM
        aka_title mt
    LEFT JOIN
        movie_link ml ON mt.id = ml.movie_id
    LEFT JOIN
        aka_title m ON ml.linked_movie_id = m.id
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')
    
    UNION ALL

    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level + 1,
        m.id AS linked_movie_id,
        ml.link_type_id
    FROM
        movie_hierarchy mh
    JOIN
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT
    a.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT ch.id) AS character_count,
    COUNT(DISTINCT kh.keyword) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY mt.production_year DESC) AS rank
FROM
    aka_name a
INNER JOIN
    cast_info ci ON ci.person_id = a.person_id
INNER JOIN
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
INNER JOIN
    title mt ON mh.movie_id = mt.id
LEFT JOIN
    char_name ch ON ch.imdb_index = a.imdb_index
LEFT JOIN
    movie_keyword mk ON mk.movie_id = mt.id
LEFT JOIN
    keyword kh ON mk.keyword_id = kh.id
WHERE 
    mt.production_year >= 2000
    AND (ci.note IS NULL OR ci.note != 'Cameo')
    AND a.name IS NOT NULL
GROUP BY
    a.name, mt.title, mt.production_year
HAVING
    COUNT(DISTINCT ch.id) > 0
ORDER BY
    rank, movie_title;
