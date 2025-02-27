WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT k.keyword) > 3
),
ActorMovies AS (
    SELECT 
        a.name AS actor_name, 
        rm.movie_id
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
),
MovieInfo AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        STRING_AGG(DISTINCT am.actor_name, ', ') AS actors
    FROM 
        RankedMovies rm
    JOIN 
        ActorMovies am ON rm.movie_id = am.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
)
SELECT 
    mi.title, 
    mi.production_year, 
    mi.actors
FROM 
    MovieInfo mi
ORDER BY 
    mi.production_year DESC, 
    mi.title ASC
LIMIT 50;
