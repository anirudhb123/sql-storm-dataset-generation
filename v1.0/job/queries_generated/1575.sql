WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 3
), FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
), ActorsWithRoles AS (
    SELECT 
        a.name,
        c.movie_id,
        r.role AS actor_role
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actor_count,
    STRING_AGG(DISTINCT awr.name || ' (' || awr.actor_role || ')', ', ') AS actors
FROM 
    FilteredMovies fm
LEFT JOIN 
    ActorsWithRoles awr ON fm.actor_count = (SELECT COUNT(*) FROM ActorsWithRoles WHERE movie_id = fm.movie_id)
GROUP BY 
    fm.title, fm.production_year, fm.actor_count
HAVING 
    COUNT(awr.name) > 0
ORDER BY 
    fm.production_year DESC, fm.title;
