WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
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
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        ac.actor_count,
        cd.company_name,
        cd.company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCount ac ON rm.id = ac.movie_id
    LEFT JOIN 
        CompanyDetails cd ON rm.id = cd.movie_id
)
SELECT 
    movie_title,
    production_year,
    actor_count,
    COALESCE(company_name, 'Unknown') AS company,
    COALESCE(company_type, 'Independent') AS type
FROM 
    FilteredMovies
WHERE 
    actor_count > 0
ORDER BY 
    production_year DESC, title_rank
LIMIT 100;
