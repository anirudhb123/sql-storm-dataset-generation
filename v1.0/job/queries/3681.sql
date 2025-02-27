WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ad.actor_count, 0) AS actor_count,
    COALESCE(mcd.company_count, 0) AS company_count,
    mcd.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorDetails ad ON rm.movie_id = ad.movie_id
LEFT JOIN 
    MovieCompanyDetails mcd ON rm.movie_id = mcd.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
