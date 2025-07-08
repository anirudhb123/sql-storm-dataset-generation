
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        t.production_year BETWEEN 1990 AND 2020
        AND a.name IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        LISTAGG(rm.actor_name, ', ') AS actor_list,
        COUNT(DISTINCT rm.actor_name) AS unique_actors
    FROM 
        RankedMovies rm
    GROUP BY 
        rm.movie_title, rm.production_year
),
TopMovies AS (
    SELECT 
        fm.movie_title,
        fm.production_year,
        fm.actor_list,
        fm.unique_actors,
        RANK() OVER (ORDER BY fm.unique_actors DESC) as actor_rank
    FROM 
        FilteredMovies fm
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.actor_list,
    tm.unique_actors
FROM 
    TopMovies tm
WHERE 
    tm.actor_rank <= 10
ORDER BY 
    tm.unique_actors DESC;
