WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT
        ak.name AS actor_name,
        ci.movie_id,
        SUM(CASE WHEN ci.nr_order IS NULL THEN 1 ELSE 0 END) AS not_ordered_roles
    FROM
        aka_name ak
    JOIN
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY
        ak.name, ci.movie_id
),
CompanyCredits AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies_involved
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
)
SELECT
    rm.movie_id,
    rm.title,
    COALESCE(rm.production_year, 'Unknown Year') AS production_year,
    ad.actor_name,
    ad.not_ordered_roles,
    cc.companies_involved
FROM
    RankedMovies rm
LEFT JOIN
    ActorDetails ad ON rm.movie_id = ad.movie_id
LEFT JOIN
    CompanyCredits cc ON rm.movie_id = cc.movie_id
WHERE
    (ad.not_ordered_roles IS NOT NULL AND ad.not_ordered_roles > 0)
    OR (cc.companies_involved IS NOT NULL)
ORDER BY
    rm.production_year DESC, rm.movie_id
FETCH FIRST 50 ROWS ONLY;
