WITH RECURSIVE movie_hierarchy AS (
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
        ml.linked_movie_id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT
    DISTINCT
    ak.name AS actor_name,
    mt.movie_title,
    mt.production_year,
    COALESCE(SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_roles,
    COUNT(DISTINCT mt.id) OVER (PARTITION BY ak.id) AS movies_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY mt.production_year DESC) AS rank
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    movie_hierarchy mt ON ci.movie_id = mt.movie_id
LEFT JOIN
    movie_keyword mk ON mt.movie_id = mk.movie_id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
WHERE
    ak.name IS NOT NULL
    AND mt.production_year BETWEEN 2000 AND 2023
GROUP BY
    ak.id, mt.movie_title, mt.production_year
HAVING
    COUNT(DISTINCT mt.id) > 5
ORDER BY
    total_roles DESC,
    rank ASC;
