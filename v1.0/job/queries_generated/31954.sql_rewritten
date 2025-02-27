WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.episode_of_id,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        at.episode_of_id,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    WHERE
        mh.level < 3 
),
FilteredMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        MovieHierarchy mh
    LEFT JOIN
        movie_companies mc ON mh.movie_id = mc.movie_id
    GROUP BY
        mh.movie_id, mh.title, mh.production_year, mh.kind_id
)
SELECT
    fm.title,
    fm.production_year,
    fm.kind_id,
    COALESCE(fc.full_cast, 0) AS full_cast_count,
    fm.company_count
FROM
    FilteredMovies fm
LEFT JOIN (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS full_cast
    FROM
        cast_info ci
    JOIN
        aka_title at ON ci.movie_id = at.id
    WHERE
        at.production_year >= 2000
    GROUP BY
        ci.movie_id
) fc ON fm.movie_id = fc.movie_id
WHERE
    fm.company_count > 0
ORDER BY
    fm.production_year DESC,
    fm.title ASC
LIMIT 50;