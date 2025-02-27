WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
), 
ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(ci.movie_id) AS movies_count
    FROM 
        aka_name a
    INNER JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(ci.movie_id) > 1
), 
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        GROUP_CONCAT(DISTINCT ai.name) AS actors,
        tm.cast_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        ActorInfo ai ON ci.person_id = ai.actor_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, tm.cast_count
)
SELECT 
    md.title,
    md.production_year,
    md.actors,
    CASE 
        WHEN md.cast_count IS NULL THEN 'No cast information'
        ELSE md.cast_count::text || ' actors'
    END AS cast_info
FROM 
    MovieDetails md
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC,
    md.cast_count DESC;
