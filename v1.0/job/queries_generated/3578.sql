WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS num_actors,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
ActorStats AS (
    SELECT
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        STRING_AGG(DISTINCT t.title, ', ') AS featured_movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
)
SELECT 
    rm.title,
    rm.production_year,
    rm.num_actors,
    as.actor_name,
    as.movies_count,
    as.featured_movies
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorStats as ON rm.num_actors > 10 AND rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.num_actors DESC, as.movies_count DESC;
