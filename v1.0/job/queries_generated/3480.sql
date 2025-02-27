WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
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
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS total_actors,
    COALESCE(ci.company_count, 0) AS total_companies,
    CASE 
        WHEN ac.actor_count IS NULL THEN 'No Actors'
        WHEN ac.actor_count > 10 THEN 'Large Cast'
        ELSE 'Small to Medium Cast' 
    END AS cast_size_category,
    ci.company_names
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCount ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title;
