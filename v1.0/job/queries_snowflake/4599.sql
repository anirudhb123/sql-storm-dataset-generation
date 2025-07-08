
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        a.person_id,
        m.movie_id,
        m.title,
        m.production_year,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        RankedMovies m ON m.movie_id = c.movie_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.person_id, m.movie_id, m.title, m.production_year
),
DistinctMovies AS (
    SELECT DISTINCT 
        am.movie_id,
        am.title,
        am.production_year,
        am.role_count
    FROM 
        ActorMovies am
    WHERE 
        am.role_count > (
            SELECT AVG(role_count) FROM ActorMovies 
            WHERE production_year = am.production_year
        )
)
SELECT 
    dm.title,
    dm.production_year,
    COUNT(CASE WHEN dm.role_count IS NOT NULL THEN 1 END) AS actor_count,
    LISTAGG(CONCAT(a.name, ' as ', rt.role), ', ') AS cast
FROM 
    DistinctMovies dm
LEFT JOIN 
    cast_info c ON c.movie_id = dm.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = c.person_id
LEFT JOIN 
    role_type rt ON rt.id = c.role_id
WHERE 
    rt.role IS NOT NULL
GROUP BY 
    dm.title, dm.production_year, dm.role_count
HAVING 
    COUNT(DISTINCT a.id) > 2
ORDER BY 
    dm.production_year DESC, dm.title;
