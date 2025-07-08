
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        c.movie_id, 
        COUNT(c.person_id) AS actor_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        am.actor_count,
        am.actors
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        ActorMovies AS am ON rm.movie_id = am.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actor_count, 0) AS total_actors,
    md.actors
FROM 
    MovieDetails AS md
WHERE 
    md.production_year IN (SELECT DISTINCT production_year FROM RankedMovies WHERE year_rank = 1)
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
