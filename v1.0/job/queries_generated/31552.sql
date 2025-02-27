WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.kind_id = 1  -- Assuming '1' indicates movie titles

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        aka_title m
    INNER JOIN
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
RankedCast AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS rank_order
    FROM
        cast_info c
    INNER JOIN
        aka_name a ON c.person_id = a.person_id
),
MoviesWithKeywords AS (
    SELECT
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mt
    INNER JOIN
        keyword k ON mt.keyword_id = k.id
    GROUP BY
        mt.movie_id
)
SELECT
    mh.title,
    mh.production_year,
    COUNT(DISTINCT rc.actor_name) AS num_actors,
    COALESCE(mwk.keywords, 'No Keywords') AS keywords,
    MAX(rc.rank_order) AS max_rank
FROM
    MovieHierarchy mh
LEFT JOIN
    RankedCast rc ON mh.movie_id = rc.movie_id
LEFT JOIN
    MoviesWithKeywords mwk ON mh.movie_id = mwk.movie_id
WHERE
    mh.production_year >= 2000
GROUP BY
    mh.title, mh.production_year, mwk.keywords
HAVING
    COUNT(DISTINCT rc.actor_name) > 2
ORDER BY
    mh.production_year DESC, mh.title;

