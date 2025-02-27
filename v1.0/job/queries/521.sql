WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
ActorCount AS (
    SELECT 
        ka.name AS actor_name,
        COUNT(ci.id) AS movie_count
    FROM 
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    GROUP BY 
        ka.name
),
FilteredActors AS (
    SELECT 
        ac.actor_name,
        ac.movie_count
    FROM 
        ActorCount ac
    WHERE 
        ac.movie_count > 1
)
SELECT 
    tm.title,
    tm.production_year,
    fa.actor_name,
    fa.movie_count
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
JOIN 
    aka_name ka ON ci.person_id = ka.person_id
JOIN 
    FilteredActors fa ON ka.name = fa.actor_name
WHERE 
    tm.production_year IS NOT NULL
ORDER BY 
    tm.production_year DESC, fa.movie_count DESC;
