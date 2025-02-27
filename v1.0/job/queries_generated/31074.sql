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
        m.title,
        m.production_year,
        mh.level + 1 AS level
    FROM
        movie_link ml
    JOIN
        aka_title m ON ml.movie_id = m.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    m.title,
    m.production_year,
    COUNT(DISTINCT c.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    AVG(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'box office') 
             THEN CAST(mi.info AS NUMERIC) 
             END) AS avg_box_office,
    SUM(CASE WHEN mt.kind_id IS NOT NULL THEN 1 ELSE 0 END) AS total_movie_kinds,
    ROW_NUMBER() OVER(PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_per_year
FROM
    MovieHierarchy m
LEFT JOIN
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN
    aka_title mt ON m.movie_id = mt.id
GROUP BY
    m.movie_id, m.title, m.production_year
HAVING
    COUNT(DISTINCT c.person_id) > 0
ORDER BY
    m.production_year, total_cast DESC;

This query starts with a recursive CTE (Common Table Expression) called `MovieHierarchy` that builds a hierarchy of movies starting from those produced in or after the year 2000. It uses a self-join through movie links.

The main SELECT statement fetches the movie title, production year, counts the total distinct actors in the cast, concatenates their names into a single string, calculates the average box office income (if available), counts different movie kinds, and assigns a rank to movies based on their year of production.

The use of various joins, aggregates, and analytic functions demonstrates complex SQL capabilities for performance benchmarking. Additionally, the logic included caters to movies with cast details and relevant box office information, filtering out those without any cast members in the `HAVING` clause.
