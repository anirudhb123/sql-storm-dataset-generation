WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title) AS year_rank
    FROM aka_title at
    WHERE at.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        ak.id AS actor_id,
        COUNT(DISTINCT ci.role_id) AS roles_count,
        STRING_AGG(DISTINCT ct.kind, ', ') AS role_types
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY c.movie_id, ak.name, ak.id
),
MoviesWithCasting AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cd.actor_name,
        cd.roles_count,
        cd.role_types
    FROM RankedMovies rm
    LEFT JOIN CastDetails cd ON rm.movie_id = cd.movie_id
    WHERE rm.year_rank <= 5 OR cd.roles_count > 2
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies_involved,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
FinalReport AS (
    SELECT 
        mwc.movie_id,
        mwc.title,
        mwc.production_year,
        mwc.actor_name,
        mwc.roles_count,
        ci.companies_involved,
        ci.total_companies,
        CASE 
            WHEN mwc.roles_count IS NULL THEN 'No actors'
            WHEN mwc.roles_count > 5 THEN 'Star studded'
            ELSE 'Few actors'
        END AS actor_summary
    FROM MoviesWithCasting mwc
    LEFT JOIN CompanyInfo ci ON mwc.movie_id = ci.movie_id
)
SELECT 
    fr.title,
    fr.production_year,
    fr.actor_name,
    fr.roles_count,
    fr.companies_involved,
    fr.total_companies,
    fr.actor_summary
FROM FinalReport fr
WHERE fr.production_year >= 2000
ORDER BY fr.production_year DESC, fr.total_companies DESC NULLS LAST
LIMIT 100;

-- Include a subquery for exceptional title lengths
AND LENGTH(fr.title) > (SELECT AVG(LENGTH(title)) FROM aka_title) 
