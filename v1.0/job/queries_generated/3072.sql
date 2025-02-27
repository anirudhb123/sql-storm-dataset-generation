WITH MovieRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS role_count,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Budget' THEN mi.info END) AS budget,
        MAX(CASE WHEN it.info = 'Gross' THEN mi.info END) AS gross
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
),
TopMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mr.role_count, 0) AS total_roles,
        COALESCE(mi.budget::numeric, 0) AS budget,
        COALESCE(mi.gross::numeric, 0) AS gross,
        ROW_NUMBER() OVER (ORDER BY COALESCE(mi.gross::numeric, 0) DESC) AS rn
    FROM 
        aka_title mt
    LEFT JOIN 
        MovieRoles mr ON mt.id = mr.movie_id
    LEFT JOIN 
        MovieInfo mi ON mt.id = mi.movie_id
    WHERE 
        mt.production_year IS NOT NULL
        AND mi.budget IS NOT NULL
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.total_roles,
    tm.budget,
    tm.gross,
    (tm.gross - tm.budget) AS profit,
    CASE 
        WHEN tm.budget = 0 THEN NULL 
        ELSE ROUND((tm.gross - tm.budget) * 100.0 / tm.budget, 2) 
    END AS return_on_investment
FROM 
    TopMovies tm
WHERE 
    tm.rn <= 10
ORDER BY 
    profit DESC;
