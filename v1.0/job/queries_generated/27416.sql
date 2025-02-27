WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastAndNames AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS actor_role,
        STRING_AGG(DISTINCT r.role, ', ') AS role_aggregation
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, a.name
),
MoviesWithCompany AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT comp.kind, ', ') AS company_types
    FROM 
        complete_cast m
    JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    JOIN 
        company_type comp ON mc.company_type_id = comp.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ca.actor_name,
    ca.actor_role,
    mwc.company_count,
    mwc.company_types
FROM 
    RankedMovies rm
LEFT JOIN 
    CastAndNames ca ON rm.movie_id = ca.movie_id
LEFT JOIN 
    MoviesWithCompany mwc ON rm.movie_id = mwc.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, rm.title;
