WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(ml.linked_movie_id, 0) AS linked_movie_id,
        1 AS level
    FROM
        aka_title mt
    LEFT JOIN
        movie_link ml ON mt.id = ml.movie_id
    WHERE
        mt.production_year >= 2000

    UNION ALL

    SELECT
        mh.movie_id,
        mt.title,
        mt.production_year,
        COALESCE(ml.linked_movie_id, 0),
        mh.level + 1
    FROM
        movie_hierarchy mh
    JOIN
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT
    m.title AS movie_title,
    m.production_year,
    m.linked_movie_id,
    COUNT(*) AS total_links,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order END) AS avg_order,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
FROM
    movie_hierarchy m
LEFT JOIN
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN
    aka_name ak ON c.person_id = ak.person_id
WHERE
    m.level <= 2
GROUP BY
    m.movie_id, m.title, m.production_year, m.linked_movie_id
ORDER BY
    m.production_year DESC, total_links DESC
LIMIT 50;

WITH genre_counts AS (
    SELECT
        mt.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS genre_count
    FROM
        aka_title mt
    LEFT JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE
        mt.production_year >= 2010
    GROUP BY
        mt.id
)
SELECT
    m.title,
    m.production_year,
    COALESCE(gc.genre_count, 0) AS genre_count,
    CASE
        WHEN m.production_year < 2015 THEN 'Pre-2015'
        ELSE 'Post-2015'
    END AS production_period,
    COUNT(DISTINCT c.person_id) AS unique_actors
FROM
    aka_title m
LEFT JOIN
    genre_counts gc ON m.id = gc.movie_id
LEFT JOIN
    cast_info c ON m.id = c.movie_id
GROUP BY
    m.title, m.production_year, gc.genre_count
HAVING
    COUNT(DISTINCT c.person_id) > 5
ORDER BY
    genre_count DESC, m.title
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
