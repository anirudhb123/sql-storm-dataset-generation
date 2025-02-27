WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.id IS NOT NULL

    UNION ALL

    SELECT
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN aka_title m ON ml.linked_movie_id = m.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorRoles AS (
    SELECT
        ak.person_id,
        ak.name,
        ci.movie_id,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY ci.nr_order) AS role_order
    FROM
        cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type rt ON ci.role_id = rt.id
),
MovieInfo AS (
    SELECT
        m.id AS movie_id,
        mi.info AS movie_info,
        mt.kind AS genre
    FROM
        aka_title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    LEFT JOIN kind_type mt ON m.kind_id = mt.id
    WHERE
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Award%')
),
DistinctActorCount AS (
    SELECT
        movie_id,
        COUNT(DISTINCT person_id) AS actor_count
    FROM
        ActorRoles
    GROUP BY
        movie_id
)
SELECT
    mh.movie_title,
    mh.production_year,
    COALESCE(dac.actor_count, 0) AS total_actors,
    ARRAY_AGG(DISTINCT ar.role) AS roles,
    COUNT(mo.movie_id) AS info_entries
FROM
    MovieHierarchy mh
LEFT JOIN DistinctActorCount dac ON mh.movie_id = dac.movie_id
LEFT JOIN ActorRoles ar ON mh.movie_id = ar.movie_id
LEFT JOIN MovieInfo mo ON mh.movie_id = mo.movie_id
WHERE
    mh.production_year BETWEEN 2000 AND 2023
GROUP BY
    mh.movie_title,
    mh.production_year,
    dac.actor_count
ORDER BY
    mh.production_year DESC,
    mh.movie_title;
