WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_title
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastWithRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        cnt.company_count
    FROM 
        movie_companies mc
    JOIN (
        SELECT 
            movie_id, 
            COUNT(DISTINCT company_id) AS company_count
        FROM 
            movie_companies
        GROUP BY 
            movie_id
    ) AS cnt ON mc.movie_id = cnt.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cwr.actor_count, 0) AS total_actors,
    COALESCE(cwr.roles, 'No roles assigned') AS actor_roles,
    COALESCE(cm.company_count, 0) AS total_companies
FROM 
    RankedMovies rm
LEFT JOIN 
    CastWithRoles cwr ON rm.movie_id = cwr.movie_id
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
WHERE 
    rm.rank_title <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
