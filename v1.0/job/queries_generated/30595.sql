WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        mt.episode_of_id
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1 AS level,
        mt.episode_of_id
    FROM
        aka_title mt
    INNER JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
RankedMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        RANK() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS year_rank
    FROM
        MovieHierarchy mh
),
ActorsWithRoles AS (
    SELECT
        c.movie_id,
        ak.name AS actor_name,
        r.role,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS total_cast
    FROM
        cast_info c
    JOIN aka_name ak ON c.person_id = ak.person_id
    JOIN role_type r ON c.role_id = r.id
    WHERE
        ak.name IS NOT NULL
),
FilteredMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        awr.actor_name,
        awr.role,
        awr.total_cast
    FROM
        RankedMovies rm
    LEFT JOIN ActorsWithRoles awr ON rm.movie_id = awr.movie_id
    WHERE
        rm.year_rank <= 5
)
SELECT
    fm.title,
    fm.production_year,
    STRING_AGG(DISTINCT fm.actor_name, ', ') AS actors,
    COUNT(DISTINCT fm.movie_id) AS movie_count,
    SUM(fm.total_cast) AS total_roles
FROM
    FilteredMovies fm
WHERE
    fm.actor_name IS NOT NULL
GROUP BY
    fm.title, fm.production_year
HAVING
    COUNT(DISTINCT fm.actor_name) > 1
ORDER BY
    fm.production_year DESC;
