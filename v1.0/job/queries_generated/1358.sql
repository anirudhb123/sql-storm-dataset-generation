WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        COUNT(DISTINCT kc.keyword) OVER (PARTITION BY t.id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5 AND rm.keyword_count > 2
),
PersonRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(pr.role_count, 0) AS total_roles
FROM 
    FilteredMovies fm
LEFT JOIN 
    PersonRoles pr ON fm.movie_id = pr.movie_id
ORDER BY 
    fm.production_year DESC, total_roles DESC
LIMIT 10;

