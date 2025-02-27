WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS movie_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.movie_rank <= 10
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' as ', r.role), ', ') AS actors
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        ci.movie_id IN (SELECT movie_id FROM TopMovies)
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        ar.actor_count,
        ar.actors
    FROM 
        TopMovies tm
    LEFT JOIN 
        ActorRoles ar ON tm.movie_id = ar.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actor_count, 0) AS number_of_actors,
    COALESCE(md.actors, 'No actors found') AS actor_list
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.title;
