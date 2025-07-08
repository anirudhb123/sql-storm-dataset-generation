
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorRoleCount AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS distinct_roles,
        COUNT(*) FILTER (WHERE ci.note IS NULL) AS null_notes
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
),
MovieCompanyCount AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        movie_companies mc
    GROUP BY
        mc.movie_id
),
FullMovieInfo AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.distinct_roles,
        ar.null_notes,
        COALESCE(mcc.company_count, 0) AS company_count,
        COALESCE(mcc.company_count, 0) +
            COALESCE(ar.null_notes, 0) AS total_association
    FROM
        RankedMovies rm
    LEFT JOIN
        ActorRoleCount ar ON rm.movie_id = ar.movie_id
    LEFT JOIN
        MovieCompanyCount mcc ON rm.movie_id = mcc.movie_id
),
MovieKeywordCount AS (
    SELECT
        movie_id,
        COUNT(DISTINCT keyword_id) AS keyword_count
    FROM
        movie_keyword
    GROUP BY
        movie_id
)
SELECT
    fmi.movie_id,
    fmi.title,
    fmi.production_year,
    fmi.distinct_roles,
    fmi.null_notes,
    fmi.company_count,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    fmi.total_association,
    CASE
        WHEN fmi.total_association > 10 THEN 'Highly Associated'
        WHEN fmi.total_association BETWEEN 5 AND 10 THEN 'Moderately Associated'
        ELSE 'Low Association'
    END AS association_category
FROM
    FullMovieInfo fmi
LEFT JOIN
    MovieKeywordCount mkc ON fmi.movie_id = mkc.movie_id
WHERE
    fmi.production_year = (SELECT MAX(production_year) FROM aka_title)
ORDER BY
    fmi.total_association DESC, fmi.title ASC
LIMIT 10;
