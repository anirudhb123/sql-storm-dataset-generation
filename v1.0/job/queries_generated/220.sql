WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS movie_name,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title AS t
    JOIN 
        title AS a ON t.movie_id = a.id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_name,
        production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(CASE WHEN r.role IS NOT NULL THEN 1 END) AS in_critical_roles
    FROM 
        cast_info AS c
    LEFT JOIN 
        role_type AS r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieMetrics AS (
    SELECT 
        tm.movie_name,
        tm.production_year,
        cd.cast_count,
        cd.in_critical_roles,
        CASE 
            WHEN cd.cast_count > 0 THEN ROUND(cd.in_critical_roles::numeric / cd.cast_count * 100, 2)
            ELSE 0 
        END AS critical_role_percentage
    FROM 
        TopMovies AS tm
    LEFT JOIN 
        CastDetails AS cd ON tm.movie_name = cd.movie_id
)
SELECT 
    mm.movie_name,
    mm.production_year,
    mm.cast_count,
    mm.in_critical_roles,
    mm.critical_role_percentage
FROM 
    MovieMetrics AS mm
WHERE 
    mm.critical_role_percentage > 50
ORDER BY 
    mm.production_year DESC, mm.critical_role_percentage DESC
LIMIT 10;
