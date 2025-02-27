WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC, mt.title) AS rn
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
), 
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 10
), 
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(ac.actor_count, 0) AS num_actors,
    (SELECT AVG(actor_count) FROM ActorCount) AS avg_actor_count,
    (SELECT COUNT(*) FROM company_name) AS total_companies,
    STRING_AGG(DISTINCT co.name, ', ') AS companies_involved
FROM 
    TopMovies tm
LEFT JOIN 
    ActorCount ac ON tm.movie_id = ac.movie_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, tm.title;
