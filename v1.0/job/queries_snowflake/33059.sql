
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        CAST(NULL AS integer) AS parent_movie_id,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.episode_of_id IS NULL

    UNION ALL

    SELECT
        e.id AS movie_id,
        e.title,
        e.production_year,
        h.movie_id AS parent_movie_id,
        h.level + 1
    FROM
        aka_title e
    JOIN
        movie_hierarchy h ON e.episode_of_id = h.movie_id
),
cast_aggregate AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM
        cast_info c
    JOIN
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
movie_keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
    GROUP BY
        mk.movie_id
)
SELECT
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(c.total_cast, 0) AS total_cast,
    COALESCE(c.cast_names, 'No Cast Information') AS cast_names,
    COALESCE(k.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN m.production_year < 2000 THEN 'Classic'
        WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    COUNT(DISTINCT ml.linked_movie_id) AS linked_movies_count,
    ROW_NUMBER() OVER (PARTITION BY CASE WHEN m.production_year < 2000 THEN 'Classic' ELSE 'Modern/Recent' END ORDER BY m.production_year) AS row_num
FROM
    movie_hierarchy m
LEFT JOIN
    cast_aggregate c ON m.movie_id = c.movie_id
LEFT JOIN
    movie_keyword_counts k ON m.movie_id = k.movie_id
LEFT JOIN
    movie_link ml ON m.movie_id = ml.movie_id
GROUP BY
    m.movie_id, m.title, m.production_year, c.total_cast, c.cast_names, k.keyword_count
HAVING
    COUNT(DISTINCT ml.linked_movie_id) > 0
ORDER BY
    era, m.production_year;
