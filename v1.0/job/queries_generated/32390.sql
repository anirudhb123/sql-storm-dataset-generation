WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::text AS parent_title,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id IN (1, 2) -- Movies or TV series

    UNION ALL

    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.title AS parent_title,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorInfo AS (
    SELECT
        ak.name AS actor_name,
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS roles_count
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ak.name, ci.movie_id
),
TitleKeyword AS (
    SELECT
        mt.id AS movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword kw ON mk.keyword_id = kw.id
    JOIN
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY
        mt.id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.parent_title,
    mh.level,
    ai.actor_name,
    COALESCE(ai.roles_count, 0) AS roles_count,
    tk.keywords
FROM
    MovieHierarchy mh
LEFT JOIN
    ActorInfo ai ON mh.movie_id = ai.movie_id
LEFT JOIN
    TitleKeyword tk ON mh.movie_id = tk.movie_id
WHERE
    mh.production_year BETWEEN 1990 AND 2023
ORDER BY
    mh.production_year DESC,
    mh.title,
    mh.level,
    ai.roles_count DESC NULLS LAST
LIMIT 100;
