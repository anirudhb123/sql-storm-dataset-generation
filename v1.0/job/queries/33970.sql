
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000
    UNION ALL
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1 AS level
    FROM
        aka_title m
    JOIN MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
CastDetails AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ci.movie_id
),
MoviesWithInfo AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(c.actor_count, 0) AS actor_count,
        COALESCE(c.actors, 'No Cast') AS actors,
        COUNT(k.keyword) AS keyword_count
    FROM
        aka_title m
    LEFT JOIN
        CastDetails c ON m.id = c.movie_id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY
        m.id, m.title, c.actor_count, c.actors
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mi.actor_count,
    mi.actors,
    mi.keyword_count,
    ROW_NUMBER() OVER (ORDER BY mi.actor_count DESC) AS actor_rank
FROM
    MovieHierarchy mh
LEFT JOIN
    MoviesWithInfo mi ON mh.movie_id = mi.movie_id
ORDER BY
    mh.production_year DESC, actor_rank
FETCH FIRST 100 ROWS ONLY;
