WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyGenre AS (
    SELECT 
        m.id AS movie_id, 
        COUNT(DISTINCT mc.company_id) AS company_count, 
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        aka_title m ON mc.movie_id = m.id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
    GROUP BY 
        m.id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    cg.company_count,
    cg.company_types,
    CASE 
        WHEN rm.actor_count > 5 THEN 'High'
        WHEN rm.actor_count BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low' 
    END AS actor_density,
    COALESCE(NULLIF(cg.company_types, ''), 'No Companies') AS output_company_types
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyGenre cg ON rm.title = cg.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year, rm.actor_count DESC
LIMIT 50;
