WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT na.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name na ON c.person_id = na.person_id
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        ar.actor_count,
        ar.actor_names,
        rm.company_count,
        CASE 
            WHEN rm.production_year >= 2000 THEN 'Modern'
            WHEN rm.production_year < 2000 AND rm.production_year >= 1980 THEN 'Classic'
            ELSE 'Vintage'
        END AS era
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.title_id = ar.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    md.actor_names,
    md.company_count,
    md.era
FROM 
    MovieDetails md
WHERE 
    md.company_count > 2
ORDER BY 
    md.production_year DESC, md.company_count DESC;
