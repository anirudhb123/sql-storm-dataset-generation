WITH RankedMovies AS (
    SELECT 
        a.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY a.title) AS rank
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        ac.actor_count
    FROM 
        RankedMovies rm
    JOIN 
        ActorCount ac ON rm.rank <= 5 AND rm.rank = ac.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    COALESCE(NULLIF(tm.actor_count, 0), 'No Actors') AS actors_info,
    CASE 
        WHEN tm.actor_count > 10 THEN 'Blockbuster'
        WHEN tm.actor_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Low' 
    END AS movie_category
FROM 
    TopMovies tm
WHERE 
    tm.production_year >= 2000
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
