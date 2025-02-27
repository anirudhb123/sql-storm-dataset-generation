
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
PopularActors AS (
    SELECT 
        an.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name an
    JOIN 
        cast_info ci ON an.person_id = ci.person_id
    WHERE 
        an.name IS NOT NULL
    GROUP BY 
        an.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT an.name, ', ') AS actors
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    rm.title,
    rm.production_year,
    pa.actor_name,
    md.actors
FROM 
    RankedMovies rm
LEFT JOIN 
    PopularActors pa ON pa.movie_count = (SELECT MAX(movie_count) FROM PopularActors)
JOIN 
    MovieDetails md ON rm.title = md.title AND rm.production_year = md.production_year
WHERE 
    rm.rn = 1
ORDER BY 
    rm.production_year DESC, rm.title;
