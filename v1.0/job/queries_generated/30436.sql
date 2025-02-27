WITH RECURSIVE MovieHierarchy AS (
    SELECT
        ct.title AS movie_title,
        ct.production_year,
        ct.id AS movie_id,
        1 AS level
    FROM
        aka_title ct
    WHERE
        ct.production_year = 2020 -- Starting point for the hierarchy

    UNION ALL

    SELECT
        at.title AS movie_title,
        at.production_year,
        at.id AS movie_id,
        mh.level + 1
    FROM
        aka_title at
    INNER JOIN movie_link ml ON ml.linked_movie_id = mh.movie_id
    INNER JOIN aka_title mh ON ml.movie_id = mh.id
    WHERE
        mh.level < 5 -- Limit the depth of the hierarchy
),
MovieCast AS (
    SELECT
        m.movie_id,
        ak.name AS actor_name,
        COUNT(*) OVER (PARTITION BY m.id) AS actor_count
    FROM
        MovieHierarchy m
    LEFT JOIN cast_info ci ON ci.movie_id = m.movie_id
    LEFT JOIN aka_name ak ON ak.person_id = ci.person_id
),
MoviesWithKeywords AS (
    SELECT
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        MovieHierarchy m
    LEFT JOIN movie_keyword mk ON mk.movie_id = m.movie_id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY
        m.movie_id
),
FinalMovies AS (
    SELECT
        mh.movie_title,
        mh.production_year,
        mc.actor_name,
        mwk.keywords,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mc.actor_count DESC) AS rank
    FROM
        MovieHierarchy mh
    LEFT JOIN MovieCast mc ON mc.movie_id = mh.movie_id
    LEFT JOIN MoviesWithKeywords mwk ON mwk.movie_id = mh.movie_id
)
SELECT
    *
FROM
    FinalMovies
WHERE
    rank <= 5 -- get top 5 movies by actor count in each production year
ORDER BY
    production_year DESC, rank;
