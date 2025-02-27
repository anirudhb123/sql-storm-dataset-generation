WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        m.compound_depth AS depth,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank
    FROM
        aka_title mt
    LEFT JOIN (
        SELECT
            m.id,
            COALESCE(
                (
                    SELECT COUNT(*)
                    FROM movie_link ml
                    WHERE ml.movie_id = m.id
                ), 0
            ) AS compound_depth
        FROM
            aka_title m
    ) m
    ON mt.id = m.id
    WHERE
        mt.production_year IS NOT NULL
    UNION ALL 
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1 AS depth,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM
        movie_link ml
    JOIN movie_hierarchy mh ON mh.movie_id = ml.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
),
cast_aggregates AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM
        cast_info c
    JOIN aka_name ak ON c.person_id = ak.person_id
    GROUP BY c.movie_id
)
SELECT
    mh.title,
    mh.production_year,
    mh.depth,
    ca.total_cast,
    ca.actor_names,
    CASE 
        WHEN ca.total_cast IS NULL THEN 'No Cast Available'
        ELSE 'Cast Information Available'
    END AS cast_status
FROM
    movie_hierarchy mh
LEFT JOIN cast_aggregates ca ON mh.movie_id = ca.movie_id
WHERE
    mh.production_year BETWEEN 2000 AND 2023
ORDER BY
    mh.production_year DESC,
    mh.title ASC;
