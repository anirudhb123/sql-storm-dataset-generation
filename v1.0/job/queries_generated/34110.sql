WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        ARRAY[mt.title] AS path
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL  -- Base case for top-level movies

    UNION ALL

    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1 AS level,
        mh.path || mt.title
    FROM
        aka_title mt
    JOIN
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id -- Recursion on episodes
),
ActorRoles AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        rt.role,
        COUNT(ci.id) AS role_count
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN
        role_type rt ON ci.role_id = rt.id
    GROUP BY
        ci.movie_id, ak.name, rt.role
),
MovieInfo AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(mi.info, 'No information') AS movie_info,
        COALESCE(w.avg_rating, 0) AS avg_rating
    FROM
        aka_title m
    LEFT JOIN (
        SELECT
            movie_id,
            STRING_AGG(info, ', ') AS info
        FROM
            movie_info
        GROUP BY
            movie_id
    ) mi ON m.id = mi.movie_id
    LEFT JOIN (
        SELECT
            movie_id,
            AVG(COALESCE(r.rating, 0)) AS avg_rating
        FROM
            movie_link ml
        LEFT JOIN
            ratings r ON ml.linked_movie_id = r.movie_id
        GROUP BY
            movie_id
    ) w ON m.id = w.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    ar.actor_name,
    ar.role,
    ar.role_count,
    mi.movie_info,
    mi.avg_rating,
    mh.level,
    mh.path
FROM
    MovieHierarchy mh
JOIN    
    ActorRoles ar ON mh.movie_id = ar.movie_id
JOIN
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE
    mh.level = 1  -- Select only top-level movies
    AND mi.avg_rating > 7.0 -- Filter movies with ratings above 7
ORDER BY
    mh.production_year DESC, -- Order by production year, newest first
    mh.title;  -- Then by title
