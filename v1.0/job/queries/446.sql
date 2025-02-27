WITH MovieRankings AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast_size
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        MovieRankings
    WHERE 
        rank_by_cast_size <= 5
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        ak.id AS actor_id,
        ci.movie_id,
        ti.production_year
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title ti ON ci.movie_id = ti.id
)
SELECT 
    tm.title,
    tm.production_year,
    COUNT(DISTINCT ad.actor_id) AS actor_count,
    STRING_AGG(DISTINCT ad.actor_name, ', ') AS actors
FROM 
    TopMovies tm
LEFT JOIN 
    ActorDetails ad ON tm.movie_id = ad.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year
HAVING 
    COUNT(DISTINCT ad.actor_id) > 0
ORDER BY 
    tm.production_year DESC, actor_count DESC;
