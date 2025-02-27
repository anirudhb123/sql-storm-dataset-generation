WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        0 AS level,
        m.production_year,
        NULL AS parent_id
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL

    UNION ALL

    SELECT
        m.id,
        m.title,
        level + 1,
        m.production_year,
        mh.movie_id
    FROM
        aka_title m
    JOIN MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
ActorRoles AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM
        cast_info ci
    GROUP BY
        ci.person_id
),
RankedActors AS (
    SELECT
        ak.name,
        ar.movie_count,
        ROW_NUMBER() OVER (ORDER BY ar.movie_count DESC) AS actor_rank
    FROM
        aka_name ak
    JOIN ActorRoles ar ON ak.person_id = ar.person_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    ra.name AS actor_name,
    ra.movie_count,
    ra.actor_rank,
    COALESCE(ki.keyword, 'No Keyword') AS keyword,
    CASE 
        WHEN ki.keyword IS NOT NULL THEN 'Keyword Present'
        ELSE 'No Keyword'
    END AS keyword_status
FROM
    MovieHierarchy mh
LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN keyword ki ON mk.keyword_id = ki.id
LEFT JOIN cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN RankedActors ra ON ci.person_id = ra.person_id
WHERE
    mh.production_year BETWEEN 2000 AND 2023
    AND (ra.movie_count > 5 OR ra.movie_count IS NULL)
ORDER BY
    mh.production_year DESC,
    ra.actor_rank ASC,
    mh.title
LIMIT 100;
