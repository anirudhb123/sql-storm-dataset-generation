WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
),
ActorCount AS (
    SELECT 
        movie_id,
        COUNT(actor_name) AS actor_count
    FROM 
        RankedMovies
    GROUP BY 
        movie_id
),
MoviesWithMoreThanTwoActors AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year
    FROM 
        RankedMovies rm
    JOIN 
        ActorCount ac ON rm.movie_id = ac.movie_id
    WHERE 
        ac.actor_count > 2
)
SELECT 
    mw.movie_id,
    mw.movie_title,
    mw.production_year,
    STRING_AGG(rm.actor_name, ', ') AS cast_list
FROM 
    MoviesWithMoreThanTwoActors mw
JOIN 
    RankedMovies rm ON mw.movie_id = rm.movie_id
GROUP BY 
    mw.movie_id, mw.movie_title, mw.production_year
ORDER BY 
    mw.production_year DESC, mw.movie_title;
