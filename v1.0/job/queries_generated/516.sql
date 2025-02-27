WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY b.name ASC) AS ranked,
        b.name AS actor_name,
        c.kind AS role_kind
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name b ON c.person_id = b.person_id
    WHERE 
        a.production_year >= 2000
),

CompanyStats AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        ARRAY_AGG(DISTINCT co.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        complete_cast m ON mc.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    rm.actor_name,
    cs.total_companies,
    cs.companies,
    CASE 
        WHEN cs.total_companies IS NULL THEN 'No Companies'
        ELSE 'Companies Present'
    END AS company_presence,
    COALESCE(rm.role_kind, 'Unknown Role') AS role_description
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyStats cs ON rm.movie_id = cs.movie_id
WHERE 
    rm.ranked <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
