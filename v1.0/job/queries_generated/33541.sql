WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        m.title,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RoleAggregates AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(CONCAT(n.name, ' (', rt.role, ')'), ', ') AS cast_details
    FROM
        cast_info ci
    JOIN
        role_type rt ON ci.role_id = rt.id
    JOIN
        aka_name n ON ci.person_id = n.person_id
    GROUP BY
        ci.movie_id
),
FilteredMovies AS (
    SELECT
        mh.movie_id,
        mh.movie_title,
        COALESCE(ra.total_cast, 0) AS total_cast,
        ra.cast_details
    FROM
        MovieHierarchy mh
    LEFT JOIN
        RoleAggregates ra ON mh.movie_id = ra.movie_id
),
YearInfo AS (
    SELECT
        t.production_year,
        COUNT(fm.movie_id) AS movie_count
    FROM
        filtered_movies fm
    JOIN
        aka_title t ON fm.movie_id = t.id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.production_year
)
SELECT
    fm.movie_id,
    fm.movie_title,
    fm.total_cast,
    fm.cast_details,
    CASE 
        WHEN yi.movie_count IS NULL THEN 'No movies found for the year'
        ELSE CAST(yi.movie_count AS text) 
    END AS count_per_year
FROM
    FilteredMovies fm
LEFT JOIN
    YearInfo yi ON fm.movie_id IN (SELECT movie_id FROM aka_title WHERE production_year = (SELECT MAX(production_year) FROM aka_title))
ORDER BY
    fm.total_cast DESC,
    fm.movie_title;
