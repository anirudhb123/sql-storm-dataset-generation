
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        mt.production_year,
        NULL AS parent_id
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT
        cm.id AS movie_id,
        cm.title,
        mh.level + 1,
        cm.production_year,
        mh.movie_id AS parent_id
    FROM
        aka_title cm
    JOIN
        MovieHierarchy mh ON cm.episode_of_id = mh.movie_id
),
CastStatistics AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    GROUP BY
        ci.movie_id
),
GenreInfo AS (
    SELECT
        mt.id AS movie_id,
        kt.keyword AS genre
    FROM
        aka_title mt
    JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN
        keyword kt ON mk.keyword_id = kt.id
    WHERE
        kt.keyword IN ('Drama', 'Action', 'Comedy')
),
MovieCompanyInfo AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    cs.total_cast,
    cs.cast_names,
    gi.genre,
    mci.total_companies,
    mci.company_names
FROM
    MovieHierarchy mh
LEFT JOIN
    CastStatistics cs ON mh.movie_id = cs.movie_id
LEFT JOIN
    GenreInfo gi ON mh.movie_id = gi.movie_id
LEFT JOIN
    MovieCompanyInfo mci ON mh.movie_id = mci.movie_id
WHERE
    mh.production_year IS NOT NULL
ORDER BY
    mh.production_year DESC,
    mh.title;
