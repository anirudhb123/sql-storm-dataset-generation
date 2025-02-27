
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
CastDetails AS (
    SELECT 
        a.name AS actor_name,
        r.role AS role_name,
        m.title,
        m.production_year,
        DENSE_RANK() OVER (PARTITION BY m.production_year ORDER BY a.name) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        title m ON ci.movie_id = m.id
    JOIN 
        role_type r ON ci.role_id = r.id
)
SELECT 
    rm.title, 
    rm.production_year, 
    COALESCE(cd.actor_name, 'Unknown') AS lead_actor, 
    COALESCE(cd.role_name, 'No Role Assigned') AS role,
    rm.cast_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.title = cd.title AND rm.production_year = cd.production_year
WHERE 
    rm.rank = 1
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
