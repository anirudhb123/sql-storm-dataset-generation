WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
NullRoleCount AS (
    SELECT 
        ci.movie_id,
        COUNT(CASE WHEN ci.role_id IS NULL THEN 1 END) AS null_role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        nrc.null_role_count
    FROM 
        RankedMovies rm
    JOIN 
        NullRoleCount nrc ON rm.movie_id = nrc.movie_id
    WHERE 
        rm.rn <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    CASE 
        WHEN tm.null_role_count > 0 THEN 'Contains unknown roles'
        ELSE 'All roles defined'
    END AS role_status
FROM 
    TopMovies tm
WHERE 
    tm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    tm.production_year DESC, tm.title ASC;
