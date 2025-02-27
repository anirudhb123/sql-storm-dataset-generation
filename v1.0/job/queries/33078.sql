WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    UNION ALL
    SELECT
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1 AS level
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT
    akn.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(mh.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT akn.name || ' (' || mh.production_year || ')', ', ') AS movie_list
FROM
    MovieHierarchy mh
JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN
    cast_info ci ON cc.subject_id = ci.person_id
JOIN
    aka_name akn ON ci.person_id = akn.person_id
WHERE
    mh.level <= 3
GROUP BY
    akn.name
HAVING
    COUNT(DISTINCT mh.movie_id) >= 5
ORDER BY
    total_movies DESC
LIMIT 10;