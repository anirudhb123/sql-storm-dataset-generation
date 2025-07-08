
WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        a.name,
        c.movie_id,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.nr_order = 1
    
    UNION ALL
    
    SELECT 
        c.person_id,
        a.name,
        c.movie_id,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON c.movie_id = ah.movie_id
    WHERE 
        c.nr_order > ah.level
),
FilteredMovies AS (
    SELECT 
        mt.movie_id,
        mt.production_year,
        mt.title,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title mt
    JOIN 
        cast_info c ON mt.movie_id = c.movie_id
    GROUP BY 
        mt.movie_id, mt.production_year, mt.title
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
),
TopMovies AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        RANK() OVER (PARTITION BY fm.production_year ORDER BY fm.actor_count DESC) AS rank,
        fm.actor_count
    FROM 
        FilteredMovies fm
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    LISTAGG(a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info c ON tm.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
WHERE 
    tm.rank <= 3
GROUP BY 
    tm.title, tm.production_year, tm.actor_count
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
