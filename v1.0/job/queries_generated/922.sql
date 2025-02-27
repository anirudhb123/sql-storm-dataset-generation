WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
SelectedMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.actor_count <= 5
),
MovieDetails AS (
    SELECT 
        sm.movie_id,
        sm.title,
        sm.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        COUNT(DISTINCT mc.company_id) AS company_count,
        SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS role_count
    FROM 
        SelectedMovies sm
    LEFT JOIN 
        complete_cast cc ON sm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON sm.movie_id = mc.movie_id
    GROUP BY 
        sm.movie_id, sm.title, sm.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_names,
    md.company_count,
    md.role_count,
    COALESCE(NULLIF(md.actor_names, ''), 'No Actors') AS final_actor_list
FROM 
    MovieDetails md
WHERE 
    md.company_count > 1
ORDER BY 
    md.production_year DESC, 
    md.role_count DESC;
