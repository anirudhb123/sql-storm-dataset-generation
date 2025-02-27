WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyImpact AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
CastPerformance AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(r.role) AS main_role
    FROM
        cast_info ci
    JOIN
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(c.count, 0) AS company_count,
    p.total_cast,
    p.main_role,
    CASE 
        WHEN p.total_cast > 10 THEN 'Large Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyImpact c ON rm.movie_id = c.movie_id
LEFT JOIN 
    CastPerformance p ON rm.movie_id = p.movie_id
WHERE 
    rm.rank_year <= 5 
    AND (c.company_type IS NULL OR c.company_type <> 'Distributor')
ORDER BY 
    rm.production_year DESC, 
    company_count DESC NULLS LAST;
