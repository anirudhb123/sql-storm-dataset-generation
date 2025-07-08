
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
PersonRoles AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        r.role AS role_type,
        COALESCE(NULLIF(c.note, ''), 'No Note Available') AS note,
        COUNT(*) OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MoviesWithRoles AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        pr.actor_name,
        pr.role_type,
        pr.note,
        pr.actor_count,
        COUNT(*) OVER (PARTITION BY rm.movie_id) AS total_roles
    FROM 
        RankedMovies rm
    LEFT JOIN 
        PersonRoles pr ON rm.movie_id = pr.movie_id
)
SELECT 
    m.title,
    m.production_year,
    LISTAGG(m.actor_name, ', ') WITHIN GROUP (ORDER BY m.actor_name) AS actors,
    MAX(m.total_roles) AS total_roles,
    COUNT(DISTINCT m.movie_id) AS unique_movies_with_actors,
    SUM(CASE 
            WHEN m.production_year IS NOT NULL THEN 1 
            ELSE 0 
        END) AS not_null_years,
    CASE 
        WHEN MAX(m.production_year) > 2000 THEN 'Modern Era'
        WHEN MAX(m.production_year) BETWEEN 1990 AND 2000 THEN '90s Culture'
        ELSE 'Classic Cinema'
    END AS era
FROM 
    MoviesWithRoles m
WHERE 
    m.role_type IS NOT NULL OR m.note IS NOT NULL
GROUP BY 
    m.title, m.production_year
HAVING 
    COUNT(DISTINCT m.actor_name) > 1 AND 
    MAX(m.production_year) IS NOT NULL
ORDER BY 
    m.production_year DESC, 
    actors;
