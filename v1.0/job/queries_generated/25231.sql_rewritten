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
        mt.production_year >= 2000
),
ActorCounts AS (
    SELECT 
        movie_id,
        COUNT(actor_name) AS actor_count
    FROM 
        RankedMovies
    GROUP BY 
        movie_id
),
TopMovies AS (
    SELECT 
        R.movie_id,
        R.movie_title,
        R.production_year,
        A.actor_count,
        R.actor_name
    FROM 
        RankedMovies R
    JOIN 
        ActorCounts A ON R.movie_id = A.movie_id
    WHERE 
        A.actor_count > 5
)
SELECT 
    T.movie_title,
    T.production_year,
    STRING_AGG(T.actor_name, ', ') AS actor_list
FROM 
    TopMovies T
GROUP BY 
    T.movie_id, T.movie_title, T.production_year
ORDER BY 
    T.production_year DESC;