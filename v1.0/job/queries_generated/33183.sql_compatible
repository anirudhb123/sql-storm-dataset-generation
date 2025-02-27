
WITH RECURSIVE CTE_MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        CAST(NULL AS integer) AS parent_id
    FROM
        aka_title m
    WHERE
        m.episode_of_id IS NULL

    UNION ALL

    SELECT
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM
        aka_title e
    JOIN
        CTE_MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),
RankedMovies AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY m.production_year DESC) AS rn
    FROM
        CTE_MovieHierarchy mh
    JOIN
        aka_title m ON mh.movie_id = m.id
    WHERE
        m.production_year IS NOT NULL
),
MovieStats AS (
    SELECT
        m.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_assigned
    FROM
        aka_title m
    LEFT JOIN
        cast_info c ON m.id = c.movie_id
    GROUP BY
        m.id
),
KeywordStats AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
FinalResults AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rs.total_cast,
        rs.roles_assigned,
        ks.keywords
    FROM
        RankedMovies rm
    LEFT JOIN
        MovieStats rs ON rm.movie_id = rs.movie_id
    LEFT JOIN
        KeywordStats ks ON rm.movie_id = ks.movie_id
    WHERE
        rm.rn <= 5
)
SELECT
    f.movie_id,
    f.title,
    f.production_year,
    COALESCE(f.total_cast, 0) AS total_cast,
    COALESCE(f.roles_assigned, 0) AS roles_assigned,
    COALESCE(f.keywords, 'No keywords') AS keywords
FROM
    FinalResults f
ORDER BY
    f.production_year DESC, f.movie_id;
