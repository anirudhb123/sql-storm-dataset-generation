WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT c.name) AS actors,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count,
        rm.actors
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
)
SELECT 
    f.title,
    f.production_year,
    f.actor_count,
    string_agg(actor, ', ') AS actor_list
FROM 
    FilteredMovies f,
    unnest(f.actors) AS actor
GROUP BY 
    f.title, f.production_year, f.actor_count
ORDER BY 
    f.actor_count DESC, f.production_year DESC;
