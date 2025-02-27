
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CTE_CastInfo AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ci.movie_id
),
CTE_MovieInfo AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        COALESCE(CI.actor_count, 0) AS actor_count,
        COALESCE(CI.actor_names, 'No Cast') AS actor_names,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rn,
        SUM(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY mt.id) AS info_count
    FROM
        aka_title mt
    LEFT JOIN
        CTE_CastInfo CI ON mt.id = CI.movie_id
    LEFT JOIN
        movie_info mi ON mt.id = mi.movie_id
)
SELECT
    mv.title,
    mv.production_year,
    mv.actor_count,
    mv.actor_names,
    COUNT(DISTINCT ml.linked_movie_id) AS linked_count,
    ARRAY_AGG(DISTINCT ml.linked_movie_id) FILTER (WHERE ml.linked_movie_id IS NOT NULL) AS linked_movies
FROM
    CTE_MovieInfo mv
LEFT JOIN
    movie_link ml ON mv.movie_id = ml.movie_id
WHERE
    mv.production_year >= 2010
GROUP BY
    mv.movie_id, mv.title, mv.production_year, mv.actor_count, mv.actor_names
HAVING
    COUNT(DISTINCT ml.linked_movie_id) > 0
ORDER BY
    mv.production_year DESC,
    mv.actor_count DESC,
    mv.title ASC
LIMIT 50;
