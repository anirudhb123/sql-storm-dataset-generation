WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT CONCAT(mi.info_type_id, ': ', mi.info), '; ') AS movie_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    ac.actor_count,
    COALESCE(cd.company_name, 'Unknown Company') AS company_name,
    COALESCE(cd.company_type, 'Unknown Type') AS company_type,
    mi.movie_details,
    CONCAT('Year Rank: ', rm.year_rank, ' | Actor Count: ', COALESCE(ac.actor_count, 0)) AS additional_info
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCount ac ON rm.title_id = ac.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.title_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.title_id = mi.movie_id
WHERE 
    rm.year_rank = 1  
ORDER BY 
    rm.production_year DESC, rm.title;