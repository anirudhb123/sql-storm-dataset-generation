WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) as actor_rank,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY at.id) AS total_actors
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year BETWEEN 2000 AND 2023
),
MovieInfo AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_name,
        mi.info AS additional_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.title = mi.info
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        STRING_AGG(actor_name, ', ') AS actors_list,
        MAX(additional_info) AS genre
    FROM 
        MovieInfo
    GROUP BY 
        title, production_year
    ORDER BY 
        production_year DESC
    LIMIT 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actors_list,
    tm.genre
FROM 
    TopMovies tm
WHERE 
    tm.genre IS NOT NULL
ORDER BY 
    tm.production_year DESC;

This SQL query benchmarks string processing by aggregating actor names associated with movies released from 2000 to 2023, categorizing them by genre, and presenting the top 10 most recent films with their respective actors and genres.
