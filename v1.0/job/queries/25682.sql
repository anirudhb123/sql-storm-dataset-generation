WITH RankedMovies AS (
    SELECT 
        ak.title AS movie_title,
        ak.production_year,
        ci.person_id,
        p.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY ak.production_year DESC) AS rank
    FROM
        aka_title ak
    JOIN
        complete_cast cc ON ak.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.id
    JOIN
        aka_name p ON ci.person_id = p.person_id
    WHERE
        ak.production_year >= 2000
        AND ak.kind_id IN (SELECT id FROM kind_type WHERE kind = 'Movie')
),
ActorMovieCount AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS movie_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
    GROUP BY 
        actor_name
),
TopActors AS (
    SELECT 
        actor_name,
        movie_count
    FROM 
        ActorMovieCount
    WHERE 
        movie_count >= 3
)
SELECT 
    ta.actor_name,
    ta.movie_count,
    ARRAY_AGG(DISTINCT rm.movie_title) AS top_movies,
    STRING_AGG(DISTINCT CAST(rm.production_year AS TEXT), ', ') AS production_years
FROM 
    TopActors ta
JOIN 
    RankedMovies rm ON ta.actor_name = rm.actor_name
GROUP BY 
    ta.actor_name, ta.movie_count
ORDER BY 
    ta.movie_count DESC;
