WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCount ac ON rm.movie_id = ac.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    STRING_AGG(a.name, ', ') AS actor_names
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
WHERE 
    md.actor_count > 0
    AND md.production_year > 2000
GROUP BY 
    md.movie_id, md.title, md.production_year, md.actor_count
ORDER BY 
    md.production_year DESC, md.title;
