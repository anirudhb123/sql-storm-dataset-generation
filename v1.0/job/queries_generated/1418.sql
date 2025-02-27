WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) AS actor_count
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
)
SELECT 
    tm.production_year,
    COUNT(*) AS total_movies,
    SUM(CASE WHEN tm.actor_count > 5 THEN 1 ELSE 0 END) AS movies_with_many_actors,
    COALESCE(AVG(tm.actor_count), 0) AS average_actor_count
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.title = mi.info
GROUP BY 
    tm.production_year
ORDER BY 
    tm.production_year DESC;
