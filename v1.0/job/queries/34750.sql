
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        NULL AS parent_movie_id,
        1 AS level
    FROM
        aka_title t
    WHERE
        t.episode_of_id IS NULL
    UNION ALL
    SELECT
        t.id,
        t.title,
        t.production_year,
        t.episode_of_id AS parent_movie_id,
        mh.level + 1
    FROM
        aka_title t
    JOIN
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
MovieCast AS (
    SELECT
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM
        complete_cast m
    JOIN
        cast_info c ON m.movie_id = c.movie_id
    GROUP BY
        m.movie_id
),
MovieInfo AS (
    SELECT
        m.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS movie_info
    FROM
        movie_info mi
    JOIN
        aka_title m ON mi.movie_id = m.id
    GROUP BY
        m.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.parent_movie_id,
    mh.level,
    COALESCE(mc.total_cast, 0) AS total_cast,
    COALESCE(mi.movie_info, 'No Info') AS movie_info,
    CASE 
        WHEN mh.level = 1 THEN 'Feature'
        ELSE 'Episode'
    END AS movie_type
FROM
    MovieHierarchy mh
LEFT JOIN
    MovieCast mc ON mh.movie_id = mc.movie_id
LEFT JOIN
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE
    mh.production_year >= 2000
GROUP BY
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.parent_movie_id,
    mh.level,
    mc.total_cast,
    mi.movie_info
ORDER BY
    mh.production_year DESC,
    mh.title ASC;
