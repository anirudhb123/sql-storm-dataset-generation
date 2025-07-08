
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
MovieWithCast AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        complete_cast m
    JOIN 
        cast_info c ON m.movie_id = c.movie_id
    GROUP BY 
        m.movie_id
), 
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mc.actor_count, 0) AS actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieWithCast mc ON rm.movie_id = mc.movie_id
    WHERE 
        rm.year_rank <= 5
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.actor_count,
    CASE 
        WHEN tm.actor_count > 10 THEN 'Ensemble Cast'
        WHEN tm.actor_count BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    LISTAGG(ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info c ON c.movie_id = tm.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = c.person_id
GROUP BY 
    tm.title, 
    tm.production_year, 
    tm.actor_count
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
