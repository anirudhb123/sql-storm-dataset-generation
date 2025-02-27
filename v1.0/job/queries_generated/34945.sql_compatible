
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level
    FROM
        title t
    WHERE
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        title mt ON ml.linked_movie_id = mt.id
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
GenreCount AS (
    SELECT
        mt.id AS movie_id,
        COUNT(kg.keyword) AS genre_count
    FROM
        movie_keyword mk
    JOIN
        keyword kg ON mk.keyword_id = kg.id
    JOIN
        title mt ON mk.movie_id = mt.id
    GROUP BY
        mt.id
),
CastRoles AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT a.name) AS actor_count,
        COUNT(DISTINCT rt.role) AS role_count,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles_list
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        role_type rt ON ci.role_id = rt.id
    GROUP BY
        ci.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(gc.genre_count, 0) AS genre_count,
    COALESCE(cr.actor_count, 0) AS actor_count,
    COALESCE(cr.role_count, 0) AS role_count,
    COALESCE(cr.roles_list, 'None') AS roles_list,
    mh.level
FROM
    MovieHierarchy mh
LEFT JOIN
    GenreCount gc ON mh.movie_id = gc.movie_id
LEFT JOIN
    CastRoles cr ON mh.movie_id = cr.movie_id
WHERE
    mh.production_year BETWEEN 1980 AND 2023
    AND COALESCE(gc.genre_count, 0) > 0
ORDER BY
    mh.production_year DESC, 
    mh.title
LIMIT 100;
