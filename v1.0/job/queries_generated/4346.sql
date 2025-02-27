WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND t.production_year IS NOT NULL
),
FilteredCast AS (
    SELECT 
        ci.movie_id, 
        a.name AS actor_name, 
        ARRAY_AGG(DISTINCT CONCAT(a.name, ' (', rc.role, ')')) AS roles
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rc ON ci.role_id = rc.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        ci.movie_id, a.name
)
SELECT 
    rm.movie_id, 
    rm.title, 
    rm.production_year,
    COALESCE(fc.roles, '{}') AS actor_roles,
    CASE 
        WHEN rm.rank = 1 THEN 'Latest'
        WHEN rm.rank <= 5 THEN 'Recent'
        ELSE 'Older'
    END AS movie_timing
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredCast fc ON rm.movie_id = fc.movie_id
WHERE 
    rm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    rm.production_year DESC, 
    rm.title;
