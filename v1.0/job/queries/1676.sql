WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_by_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_year <= 5
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.person_role_id,
        rt.role AS person_role
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.person_role_id = rt.id
)
SELECT 
    tm.title,
    tm.production_year,
    COUNT(CS.person_id) AS total_cast,
    STRING_AGG(DISTINCT p.name, ', ') AS cast_names
FROM 
    TopMovies tm
LEFT JOIN 
    CastInfoWithRoles CS ON tm.movie_id = CS.movie_id
LEFT JOIN 
    aka_name p ON CS.person_id = p.person_id
WHERE 
    p.name IS NOT NULL
GROUP BY 
    tm.movie_id, tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, total_cast DESC;
