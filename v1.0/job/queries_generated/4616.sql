WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year >= 2000
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        c.name AS company_name,
        r.role AS actor_role
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.movie_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        movie_companies mc ON rm.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
)
SELECT 
    tm.production_year,
    COUNT(DISTINCT tm.title) AS total_movies,
    STRING_AGG(DISTINCT tm.actor_role, ', ') AS roles,
    COALESCE(SUM(NULLIF(tm.actor_role IS NOT NULL, 0)), 0) AS role_count
FROM 
    TopMovies tm
WHERE 
    tm.company_name IS NOT NULL
GROUP BY 
    tm.production_year
HAVING 
    COUNT(DISTINCT tm.title) > 5
ORDER BY 
    tm.production_year DESC;
