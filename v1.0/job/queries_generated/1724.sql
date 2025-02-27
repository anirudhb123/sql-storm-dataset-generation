WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
    FROM 
        title t
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
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MoviesWithCompanies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        A.actor_count,
        M.companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts A ON rm.movie_id = A.movie_id
    LEFT JOIN 
        MovieCompanyInfo M ON rm.movie_id = M.movie_id
)

SELECT 
    mwc.title,
    mwc.production_year,
    COALESCE(mwc.actor_count, 0) AS total_actors,
    COALESCE(mwc.companies, 'No companies') AS companies,
    CASE 
        WHEN mwc.production_year >= 2000 THEN 'Modern Era'
        WHEN mwc.production_year >= 1980 THEN 'Classic Era'
        ELSE 'Golden Era'
    END AS era
FROM 
    MoviesWithCompanies mwc
WHERE 
    mwc.rank_per_year <= 5
ORDER BY 
    mwc.production_year DESC, mwc.title
LIMIT 10;
