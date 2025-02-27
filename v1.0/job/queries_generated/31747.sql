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
        mt.episode_of_id IS NULL
    UNION ALL
    SELECT
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1 AS level,
        mh.path || e.title
    FROM
        aka_title e
    INNER JOIN
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),
MovieWithKeywords AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        RANK() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
),
AggregatedMovieInfo AS (
    SELECT
        mwk.movie_id,
        mwk.title,
        mwk.production_year,
        STRING_AGG(mwk.keyword, ', ') AS keywords
    FROM
        MovieWithKeywords mwk
    WHERE
        mwk.keyword_rank <= 5 -- get top 5 keywords
    GROUP BY
        mwk.movie_id, mwk.title, mwk.production_year
),
MovieCast AS (
    SELECT
        c.movie_id,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    GROUP BY
        c.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ami.keywords, 'No keywords') AS keywords,
    COALESCE(mc.cast_count, 0) AS cast_count,
    COALESCE(mc.actors, 'No cast available') AS actors,
    mh.level,
    mh.path
FROM
    MovieHierarchy mh
LEFT JOIN
    AggregatedMovieInfo ami ON mh.movie_id = ami.movie_id
LEFT JOIN
    MovieCast mc ON mh.movie_id = mc.movie_id
ORDER BY
    mh.production_year DESC,
    mh.level ASC;
