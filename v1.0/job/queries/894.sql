
WITH RankedMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    INNER JOIN 
        cast_info c ON a.person_id = c.person_id
    INNER JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
),
ActorStats AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count,
        AVG(production_year) AS avg_year
    FROM 
        RankedMovies
    WHERE 
        rn = 1
    GROUP BY 
        actor_id, actor_name
),
TopActors AS (
    SELECT 
        actor_id,
        actor_name,
        movie_count,
        avg_year,
        RANK() OVER (ORDER BY movie_count DESC) AS actor_rank
    FROM 
        ActorStats
),
YearlyMovies AS (
    SELECT 
        production_year,
        COUNT(*) AS movies_released
    FROM 
        aka_title
    GROUP BY 
        production_year
)
SELECT 
    ta.actor_name,
    ta.movie_count,
    ta.avg_year,
    ym.movies_released,
    COALESCE(ROUND((CAST(ta.movie_count AS DECIMAL) / NULLIF(ym.movies_released, 0)) * 100, 2), 0) AS movie_percentage
FROM 
    TopActors ta
LEFT JOIN 
    YearlyMovies ym ON ta.avg_year = ym.production_year
WHERE 
    ta.actor_rank <= 10
ORDER BY 
    ta.actor_rank;
