
WITH RECURSIVE MoviePaths AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS level,
        ARRAY_CONSTRUCT(m.id) AS path
    FROM
        aka_title m
    WHERE
        m.production_year > 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        mp.level + 1,
        ARRAY_CAT(mp.path, ARRAY_CONSTRUCT(m.id)) AS path
    FROM
        MoviePaths mp
    JOIN
        movie_link ml ON ml.movie_id = mp.movie_id
    JOIN
        aka_title m ON m.id = ml.linked_movie_id
    WHERE
        mp.level < 5 AND  
        NOT m.id IN (SELECT value FROM TABLE(FLATTEN(input => mp.path)))  
),
ActorRoles AS (
    SELECT
        a.name AS actor_name,
        c.movie_id,
        r.role AS role_type,
        ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY c.nr_order) AS role_order
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON r.id = c.role_id
    WHERE
        r.role NOT LIKE '%extra%' AND
        a.name IS NOT NULL
),
MoviesWithActorRoles AS (
    SELECT
        mp.movie_id,
        mp.movie_title,
        ar.actor_name,
        ar.role_type,
        mp.level
    FROM
        MoviePaths mp
    LEFT JOIN
        ActorRoles ar ON mp.movie_id = ar.movie_id
),
FilteredMovies AS (
    SELECT
        mw.actor_name,
        mw.movie_title,
        mw.level,
        COALESCE(mw.role_type, 'Unknown') AS role_type,
        COUNT(*) OVER (PARTITION BY mw.actor_name) AS total_movies
    FROM
        MoviesWithActorRoles mw
    WHERE
        (mw.level > 2 AND mw.role_type IS NOT NULL)
        OR (mw.role_type IS NULL AND mw.level = 1)  
)
SELECT
    f.actor_name,
    LISTAGG(f.movie_title, ', ') WITHIN GROUP (ORDER BY f.level) AS movies,
    MAX(f.level) AS max_level,
    SUM(CASE WHEN f.role_type = 'Director' THEN 1 ELSE 0 END) AS director_count,
    COUNT(IF(f.role_type IS NOT NULL, 1, NULL)) AS defined_roles,
    f.total_movies
FROM
    FilteredMovies f
GROUP BY
    f.actor_name, f.total_movies, f.level
HAVING
    f.total_movies > 3  
ORDER BY
    max_level DESC, f.actor_name;
