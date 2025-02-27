WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.production_year > 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        title m ON ml.linked_movie_id = m.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    CONCAT(a.name, ' (', a.id, ')') AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    AVG(CASE WHEN m.production_year IS NOT NULL THEN m.production_year END) AS avg_production_year,
    STRING_AGG(DISTINCT DISTINCT t.title, ', ') AS movie_titles,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_associated,
    (SELECT COUNT(*) FROM aka_name an WHERE an.person_id = a.id) AS other_name_count
FROM
    aka_name a
LEFT JOIN
    cast_info c ON a.person_id = c.person_id
LEFT JOIN
    title t ON c.movie_id = t.id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    MovieHierarchy m ON m.movie_id = c.movie_id
GROUP BY
    a.id, a.name
HAVING
    COUNT(DISTINCT c.movie_id) > 10
ORDER BY
    total_movies DESC;
