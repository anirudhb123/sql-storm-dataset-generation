WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS role_rank,
        COALESCE(SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_roles
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id 
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularActors AS (
    SELECT 
        name.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        name
    JOIN 
        cast_info ci ON name.id = ci.person_id
    GROUP BY 
        name.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
MovieRoleAnalysis AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS average_roles,
        SUM(CASE WHEN ci.role_id IS NULL THEN 1 ELSE 0 END) AS null_role_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.role_rank,
    mra.average_roles,
    mra.null_role_count,
    pa.name AS popular_actor
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieRoleAnalysis mra ON rm.movie_id = mra.movie_id
LEFT JOIN 
    PopularActors pa ON pa.movie_count >= 10
WHERE 
    rm.total_roles > 0 
    AND (mra.average_roles IS NOT NULL OR mra.null_role_count > 0)
ORDER BY 
    rm.production_year DESC, 
    rm.role_rank ASC, 
    pa.name DESC
LIMIT 50 OFFSET 5
UNION
SELECT 
    null AS movie_id,
    'N/A' AS title,
    NULL AS production_year,
    NULL AS role_rank,
    0 AS average_roles,
    0 AS null_role_count,
    'No actors found' AS popular_actor
WHERE NOT EXISTS (SELECT 1 FROM RankedMovies)
ORDER BY random()

