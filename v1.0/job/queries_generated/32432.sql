WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        1 as level
    FROM
        aka_title mt
    WHERE
        mt.production_year = 2022

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE
        mh.level < 5  -- limiting the depth for performance
)

SELECT
    ak.name AS actor_name,
    at.title AS movie_title,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT cc.id) AS total_cast,
    AVG(CASE WHEN mi.info IS NOT NULL THEN LENGTH(mi.info) ELSE 0 END) AS avg_info_length,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY at.production_year DESC) AS actor_rank
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')
LEFT JOIN
    aka_title at ON mh.movie_id = at.id
WHERE
    ak.name IS NOT NULL
GROUP BY
    ak.name, at.title
HAVING
    COUNT(DISTINCT ci.id) > 3 -- actor must have appeared in more than 3 movies
ORDER BY
    actor_rank ASC, total_cast DESC;
