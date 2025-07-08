WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank
    FROM
        MovieHierarchy mh
)
SELECT
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT ml.linked_movie_id) AS linked_movies_count,
    COALESCE(i.info, 'No Additional Info') AS additional_info,
    nt.gender
FROM
    cast_info ci
JOIN
    aka_name ak ON ci.person_id = ak.person_id
JOIN
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN
    movie_link ml ON mt.id = ml.movie_id
LEFT JOIN
    movie_info i ON mt.id = i.movie_id AND i.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
LEFT JOIN
    name nt ON ak.person_id = nt.imdb_id
WHERE
    mt.production_year > 2000
    AND ak.name IS NOT NULL
GROUP BY
    ak.name, mt.title, mt.production_year, i.info, nt.gender
HAVING
    COUNT(DISTINCT ml.linked_movie_id) > 0
ORDER BY
    mt.production_year DESC, COUNT(DISTINCT ml.linked_movie_id) DESC;