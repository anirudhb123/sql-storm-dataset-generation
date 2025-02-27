WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
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
CompCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS total_actors,
    COALESCE(cc.company_names, 'No Companies') AS production_companies,
    CASE 
        WHEN rm.year_rank = 1 THEN 'Latest Release'
        ELSE 'Previous Release'
    END AS release_status
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCount ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    CompCompanies cc ON rm.movie_id = cc.movie_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, total_actors DESC;
