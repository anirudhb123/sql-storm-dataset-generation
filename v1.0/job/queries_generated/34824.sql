WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = 1  -- Assuming 1 for movies

    UNION ALL

    SELECT
        mv.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN movie_link mv ON mh.movie_id = mv.movie_id
    JOIN aka_title mt ON mv.linked_movie_id = mt.id
    WHERE
        mt.kind_id = 1  -- Filtering for movies only
),
TopMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank
    FROM
        MovieHierarchy mh
),
FilteredMovies AS (
    SELECT
        tm.movie_id,
        tm.title,
        tm.production_year
    FROM
        TopMovies tm
    WHERE
        tm.rank <= 5  -- Get top 5 movies per year
),
PersonRoles AS (
    SELECT
        ci.person_id,
        ci.movie_id,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY ci.nr_order) AS role_rank
    FROM
        cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
)
SELECT
    pm.name AS person_name,
    fm.title AS movie_title,
    fm.production_year,
    pr.role AS character_role,
    ci.note AS cast_note
FROM
    FilteredMovies fm
JOIN cast_info ci ON fm.movie_id = ci.movie_id
JOIN aka_name pm ON ci.person_id = pm.person_id
LEFT JOIN PersonRoles pr ON ci.person_id = pr.person_id AND ci.movie_id = pr.movie_id
WHERE
    ci.note IS NOT NULL
ORDER BY
    fm.production_year DESC, fm.title ASC, pm.name;
