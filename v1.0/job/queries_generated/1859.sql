WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
),
CompanyMovies AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),
MovieInfo AS (
    SELECT
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS movie_info
    FROM
        movie_info mi
    GROUP BY
        mi.movie_id
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS total_actors,
    COALESCE(cm.company_name, 'Independent') AS production_company,
    COALESCE(mo.movie_info, 'No additional info') AS additional_info
FROM
    RankedMovies rm
LEFT JOIN
    ActorCounts ac ON rm.movie_id = ac.movie_id
LEFT JOIN
    CompanyMovies cm ON rm.movie_id = cm.movie_id
LEFT JOIN
    MovieInfo mo ON rm.movie_id = mo.movie_id
WHERE
    rm.year_rank <= 5
ORDER BY
    rm.production_year DESC, total_actors DESC;
