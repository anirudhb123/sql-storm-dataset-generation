
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_title
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        SUM(CASE WHEN c.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_filled,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        c.movie_id
),
CompanyInfo AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name) AS companies,
        MAX(ct.kind) AS company_kind
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
CompleteMovieInfo AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cd.total_cast, 0) AS total_cast,
        COALESCE(cd.roles_filled, 0) AS roles_filled,
        ci.companies,
        ci.company_kind,
        mk.keywords
    FROM
        RankedMovies rm
    LEFT JOIN
        CastDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN
        CompanyInfo ci ON rm.movie_id = ci.movie_id
    LEFT JOIN
        MovieKeywords mk ON rm.movie_id = mk.movie_id
),
FinalBenchmark AS (
    SELECT
        *,
        CASE
            WHEN total_cast IS NULL THEN 0
            ELSE total_cast
        END AS adjusted_cast_count,
        CASE
            WHEN roles_filled IS NULL THEN 'Unknown'
            WHEN roles_filled = total_cast THEN 'Fully Casted'
            ELSE 'Partially Casted'
        END AS cast_status
    FROM
        CompleteMovieInfo
    WHERE
        (production_year IS NOT NULL AND production_year > 2000)
        OR (keywords IS NOT NULL AND POSITION('Award' IN keywords) > 0)
)

SELECT
    fb.title,
    fb.production_year,
    fb.total_cast,
    fb.adjusted_cast_count,
    fb.cast_status,
    fb.companies,
    fb.company_kind,
    fb.keywords
FROM
    FinalBenchmark fb
WHERE
    fb.adjusted_cast_count > 2
ORDER BY
    fb.production_year DESC,
    fb.title ASC;
