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
FilteredMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year 
    FROM 
        RankedMovies rm 
    WHERE 
        rm.rank <= 10
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.role_id,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    INNER JOIN 
        role_type rt ON ci.role_id = rt.id
),
MoviesAndCast AS (
    SELECT 
        fm.title,
        fm.production_year,
        c.person_id,
        c.role,
        CASE 
            WHEN c.role IS NULL THEN 'Unknown Role'
            ELSE c.role
        END AS display_role
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        CastInfoWithRoles c ON fm.movie_id = c.movie_id
)
SELECT 
    mac.title,
    mac.production_year,
    COUNT(DISTINCT mac.person_id) AS total_cast,
    STRING_AGG(DISTINCT mac.display_role, ', ') AS roles_list
FROM 
    MoviesAndCast mac
GROUP BY 
    mac.title, mac.production_year
HAVING 
    COUNT(DISTINCT mac.person_id) > 0
ORDER BY 
    mac.production_year DESC, mac.title;
