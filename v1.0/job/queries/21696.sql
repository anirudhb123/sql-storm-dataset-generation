WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        t.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS year_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
),
ActorRoles AS (
    SELECT 
        a.name,
        c.person_id,
        c.movie_id,
        r.role AS actor_role,
        COUNT(c.role_id) AS role_count,
        AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS null_notes_ratio
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    LEFT JOIN 
        role_type r ON r.id = c.role_id
    GROUP BY 
        a.name, c.person_id, c.movie_id, r.role
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT m.id) AS company_count,
        STRING_AGG(DISTINCT cp.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name m ON m.id = mc.company_id
    JOIN 
        company_type cp ON cp.id = mc.company_type_id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    ar.name AS actor_name,
    ar.actor_role,
    ar.role_count,
    mci.company_count,
    mci.company_types,
    COALESCE(NULLIF(rm.year_count, 0), 1) AS valid_year_count 
FROM 
    RankedMovies rm
JOIN 
    ActorRoles ar ON ar.movie_id = rm.movie_id
LEFT JOIN 
    MovieCompanyInfo mci ON mci.movie_id = rm.movie_id
WHERE 
    (ar.role_count > 1 OR mci.company_count IS NULL) 
    AND ((rm.production_year % 2 = 0 AND ar.name IS NOT NULL) OR ar.name IS NULL) 
ORDER BY 
    rm.production_year DESC, ar.role_count DESC, ar.name;