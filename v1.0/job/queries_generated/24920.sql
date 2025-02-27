WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.kinds_id IN (SELECT id FROM kind_type WHERE kind = 'movie') AND
        m.production_year IS NOT NULL
    UNION ALL
    SELECT
        m.linked_movie_id AS movie_id,
        m2.title AS movie_title,
        m2.production_year,
        mh.level + 1 AS level
    FROM
        movie_link m
    JOIN
        aka_title m2 ON m.linked_movie_id = m2.id
    JOIN
        movie_hierarchy mh ON m.movie_id = mh.movie_id
),
movie_details AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(COUNT(c.id), 0) AS cast_count,
        COALESCE(STRING_AGG(DISTINCT a.name, ', '), 'None') AS cast_names,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM
        aka_title m
    LEFT JOIN
        cast_info c ON m.id = c.movie_id
    LEFT JOIN
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN
        movie_keyword k ON m.id = k.movie_id
    GROUP BY
        m.id
)
SELECT
    mh.movie_title,
    mh.production_year,
    md.cast_count,
    md.cast_names,
    md.keyword_count,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY md.cast_count DESC) AS rank,
    NULLIF(md.cast_count, 0) AS adjusted_cast_count
FROM
    movie_hierarchy mh
JOIN
    movie_details md ON mh.movie_id = md.movie_id
WHERE
    mh.level = 1
    AND md.production_year >= 2000
    AND md.cast_count IS NOT NULL
ORDER BY
    mh.production_year, md.cast_count DESC;
