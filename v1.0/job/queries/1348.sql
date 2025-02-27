WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM cast('2024-10-01' as date)) - t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        a.name AS actor_name,
        STRING_AGG(DISTINCT r.role, ', ') AS roles,
        COUNT(DISTINCT c.movie_id) AS movies_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
MovieCompanies AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        c.country_code,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    a.actor_name,
    a.roles,
    a.movies_count,
    mc.company_name,
    mc.country_code
FROM 
    RankedMovies r
LEFT JOIN 
    ActorRoles a ON a.movies_count > 5
LEFT JOIN 
    MovieCompanies mc ON r.movie_id = mc.movie_id
WHERE 
    r.year_rank = 1 
    AND (mc.country_code IS NULL OR mc.country_code = 'USA')
ORDER BY 
    r.production_year DESC, a.movies_count DESC
LIMIT 100;