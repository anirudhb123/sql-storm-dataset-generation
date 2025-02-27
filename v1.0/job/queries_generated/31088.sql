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
        aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    ak.name AS actor_name,
    mt.title AS movie_title,
    mh.level AS movie_level,
    AVG(vp.rating) AS average_rating,
    COUNT(DISTINCT mk.keyword) AS total_keywords,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords_list
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    aka_title mt ON ci.movie_id = mt.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
LEFT JOIN
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN
    (SELECT movie_id, AVG(rating) AS rating
     FROM (
         SELECT movie_id, rating
         FROM movie_info mi
         WHERE mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
         AND mi.info IS NOT NULL
     ) AS rated_movies
     GROUP BY movie_id) vp ON mt.id = vp.movie_id
WHERE
    mt.production_year BETWEEN 2000 AND 2023
    AND ak.name IS NOT NULL
GROUP BY
    ak.name, mt.title, mh.level
HAVING
    COUNT(DISTINCT mk.keyword) > 5
ORDER BY
    mh.level, average_rating DESC;
