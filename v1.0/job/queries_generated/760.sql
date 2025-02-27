WITH RankedMovies AS (
    SELECT
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rank
    FROM
        aka_title at
    WHERE
        at.production_year IS NOT NULL
),
CastDetails AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        ci.nr_order,
        rt.role
    FROM
        cast_info ci
        JOIN aka_name ak ON ci.person_id = ak.person_id
        JOIN role_type rt ON ci.role_id = rt.id
),
MovieCompanies AS (
    SELECT
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM
        movie_companies mc
        JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    COALESCE(rm.production_year, 'Unknown') AS production_year,
    cd.actor_name,
    cd.nr_order,
    COALESCE(mc.companies, 'No Companies') AS companies,
    COUNT(*) OVER (PARTITION BY rm.production_year) AS movie_count,
    CASE 
        WHEN rm.rank <= 5 THEN 'Top 5 Movies'
        ELSE 'Other Movies'
    END AS movie_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE 
    cd.actor_name IS NOT NULL OR mc.companies IS NOT NULL
ORDER BY 
    rm.production_year, rm.title, cd.nr_order;
