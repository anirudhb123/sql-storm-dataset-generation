WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS year_rank
    FROM
        aka_title a
    WHERE
        a.production_year IS NOT NULL
),
MovieRoles AS (
    SELECT
        c.movie_id,
        r.role,
        COUNT(c.id) AS role_count
    FROM
        cast_info c
    JOIN
        role_type r ON c.role_id = r.id
    GROUP BY
        c.movie_id, r.role
),
MovieStatistics AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(SUM(CASE WHEN kr.keyword = 'Action' THEN 1 ELSE 0 END), 0) AS action_keywords,
        COALESCE(SUM(CASE WHEN kr.keyword = 'Drama' THEN 1 ELSE 0 END), 0) AS drama_keywords,
        COALESCE(SUM(CASE WHEN kr.keyword = 'Comedy' THEN 1 ELSE 0 END), 0) AS comedy_keywords
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword kr ON mk.keyword_id = kr.id
    GROUP BY
        m.id
),
FinalMetrics AS (
    SELECT
        ms.movie_id,
        ms.title,
        ms.production_year,
        COALESCE(mr.role_count, 0) AS role_count,
        COALESCE(rm.year_rank, 0) AS year_rank,
        ms.action_keywords,
        ms.drama_keywords,
        ms.comedy_keywords
    FROM
        MovieStatistics ms
    LEFT JOIN
        MovieRoles mr ON ms.movie_id = mr.movie_id
    LEFT JOIN
        RankedMovies rm ON ms.movie_id = rm.id
)
SELECT
    title,
    production_year,
    role_count,
    year_rank,
    action_keywords,
    drama_keywords,
    comedy_keywords
FROM
    FinalMetrics
WHERE
    (action_keywords > 0 OR drama_keywords > 0 OR comedy_keywords > 0)
    AND year_rank <= 5
ORDER BY
    production_year DESC, title ASC
LIMIT 100;
