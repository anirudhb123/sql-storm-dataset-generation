WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
), 
CastStatistics AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS cast_count,
        AVG(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    cs.cast_count,
    cs.avg_roles,
    ci.company_count,
    ci.company_names
FROM 
    RankedMovies rm
LEFT JOIN 
    CastStatistics cs ON rm.title = (SELECT t.title FROM aka_title t WHERE t.id = cs.movie_id)
LEFT JOIN 
    CompanyInfo ci ON rm.title = (SELECT t.title FROM aka_title t WHERE t.id = ci.movie_id)
WHERE 
    rm.rn <= 5
ORDER BY 
    rm.production_year DESC, rm.title;
