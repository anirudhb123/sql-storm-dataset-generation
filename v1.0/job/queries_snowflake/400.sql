WITH MovieRoles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
TopMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        mrc.role,
        mrc.role_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mrc.role_count DESC) AS rn
    FROM 
        aka_title mt
    LEFT JOIN 
        MovieRoles mrc ON mt.id = mrc.movie_id
    WHERE 
        mt.production_year IS NOT NULL
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.role, 'Unnamed') AS role,
    tm.role_count
FROM 
    TopMovies tm
WHERE 
    tm.rn <= 5
ORDER BY 
    tm.production_year DESC, 
    tm.role_count DESC;