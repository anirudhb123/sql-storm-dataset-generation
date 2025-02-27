WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.imdb_index,
        1 AS level
    FROM
        aka_title AS mt
    WHERE
        mt.production_year >= 2000

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        atk.title AS movie_title,
        atk.production_year,
        atk.imdb_index,
        mh.level + 1 AS level
    FROM
        movie_link AS ml
    JOIN
        aka_title AS atk ON ml.linked_movie_id = atk.id
    JOIN
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
)
SELECT
    n.gender,
    a.name AS actor_name,
    m.movie_title,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(ri.info) AS average_rating,
    ROW_NUMBER() OVER (PARTITION BY n.gender ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS rank
FROM
    aka_name AS a
JOIN
    cast_info AS ci ON a.person_id = ci.person_id
JOIN
    MovieHierarchy AS m ON m.movie_id = ci.movie_id
LEFT JOIN
    movie_keyword AS mk ON mk.movie_id = m.movie_id
LEFT JOIN
    keyword AS kc ON mk.keyword_id = kc.id
LEFT JOIN
    (SELECT
        mi.movie_id,
        AVG(CASE WHEN it.info = 'Rating' THEN CAST(mi.info AS DECIMAL) END) AS info
     FROM
        movie_info AS mi
     JOIN
        info_type AS it ON mi.info_type_id = it.id
     WHERE
        it.info = 'Rating'
     GROUP BY
        mi.movie_id) AS ri ON ri.movie_id = m.movie_id
JOIN
    name AS n ON n.imdb_id = a.id
WHERE
    n.gender IS NOT NULL
GROUP BY
    n.gender, a.name, m.movie_title, m.production_year
HAVING
    COUNT(DISTINCT kc.keyword) > 0
ORDER BY
    n.gender, keyword_count DESC;