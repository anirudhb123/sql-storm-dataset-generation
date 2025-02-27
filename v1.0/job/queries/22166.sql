WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.title IS NOT NULL 
        AND t.production_year IS NOT NULL
),
ActorMovieJoin AS (
    SELECT 
        a.name AS actor_name,
        am.movie_id,
        am.nr_order AS actor_order,
        mn.gender,
        RANK() OVER (PARTITION BY am.movie_id ORDER BY am.nr_order) AS actor_rank
    FROM 
        cast_info am
    JOIN 
        aka_name a ON a.person_id = am.person_id
    JOIN 
        name mn ON mn.id = a.person_id
    WHERE 
        mn.gender IN ('M', 'F')
),
CompanyMovieJoin AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON c.id = mc.company_id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(am.actor_names, 'No Actors') AS actors,
    COALESCE(cm.company_count, 0) AS company_count,
    COALESCE(cm.company_names, 'N/A') AS companies,
    CASE 
        WHEN rm.production_year > 2000 THEN 'Modern'
        WHEN rm.production_year BETWEEN 1980 AND 2000 THEN 'Classic'
        ELSE 'Old'
    END AS era,
    CASE 
        WHEN am.actor_rank IS NULL THEN 'No rankings available'
        ELSE 'Ranked'
    END AS rank_status
FROM 
    RankedMovies rm
LEFT JOIN (
    SELECT 
        movie_id,
        STRING_AGG(actor_name, ', ') AS actor_names,
        MAX(actor_rank) AS actor_rank
    FROM 
        ActorMovieJoin
    GROUP BY 
        movie_id
) am ON am.movie_id = rm.movie_id
LEFT JOIN CompanyMovieJoin cm ON cm.movie_id = rm.movie_id
WHERE 
    rm.production_year BETWEEN 1980 AND EXTRACT(YEAR FROM cast('2024-10-01' as date))
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;