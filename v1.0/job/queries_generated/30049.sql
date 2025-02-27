WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
)
, actor_roles AS (
    SELECT
        ci.person_id,
        ci.movie_id,
        ci.role_id,
        COUNT(ci.id) AS role_count
    FROM
        cast_info ci
    GROUP BY
        ci.person_id, ci.movie_id, ci.role_id
)
, ranked_actors AS (
    SELECT
        ar.person_id,
        ar.movie_id,
        ar.role_id,
        ar.role_count,
        ROW_NUMBER() OVER (PARTITION BY ar.movie_id ORDER BY ar.role_count DESC) AS rank
    FROM
        actor_roles ar
)
SELECT
    mh.title AS movie_title,
    mh.production_year,
    ak.name AS actor_name,
    ra.role_count,
    ra.rank
FROM
    movie_hierarchy mh
LEFT JOIN
    ranked_actors ra ON mh.movie_id = ra.movie_id
LEFT JOIN
    aka_name ak ON ra.person_id = ak.person_id
WHERE
    mh.level <= 3 AND
    (ra.rank IS NULL OR ra.role_count > 2) 
ORDER BY
    mh.production_year DESC, mh.title, ra.rank;

