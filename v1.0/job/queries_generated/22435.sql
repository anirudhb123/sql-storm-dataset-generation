WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
        JOIN movie_companies mc ON t.movie_id = mc.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND mc.company_type_id IN (
            SELECT id FROM company_type WHERE kind = 'Production'
        )
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        r.role,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
        JOIN role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, ci.person_id, r.role
),
DistinctTitles AS (
    SELECT DISTINCT 
        t.title 
    FROM 
        aka_title t 
    ORDER BY 
        t.title
),
CoalescedInfo AS (
    SELECT 
        pi.person_id,
        COALESCE(pi.info, 'No Info Available') AS person_info
    FROM 
        person_info pi
)
SELECT 
    mv.title AS movie_title,
    mv.production_year,
    r.role,
    COUNT(DISTINCT ca.person_id) AS actor_count,
    MIN(COALESCE(ci.person_info, 'Information Missing')) AS actor_info,
    mv.title_rank
FROM 
    RankedMovies mv
LEFT JOIN 
    CastRoles ca ON mv.movie_id = ca.movie_id
LEFT JOIN 
    CoalescedInfo ci ON ca.person_id = ci.person_id
LEFT JOIN 
    DistinctTitles dt ON mv.title = dt.title
WHERE 
    dt.title IS NULL OR dt.title IS NOT NULL
GROUP BY 
    mv.movie_id, mv.title, mv.production_year, r.role, mv.title_rank
HAVING 
    COUNT(DISTINCT ca.person_id) > 0 
    AND mv.production_year BETWEEN 1980 AND 1990
ORDER BY 
    mv.production_year DESC, actor_count DESC;
