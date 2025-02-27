WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyInformation AS (
    SELECT 
        mc.movie_id,
        com.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name com ON mc.company_id = com.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    ci.company_name,
    ci.company_type,
    (SELECT COUNT(DISTINCT kw.keyword) 
     FROM movie_keyword mk
     JOIN keyword kw ON mk.keyword_id = kw.id
     WHERE mk.movie_id = rm.id) AS keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyInformation ci ON rm.id = ci.movie_id
WHERE 
    rm.cast_count > 5 AND (ci.company_name IS NOT NULL OR ci.company_type IS NOT NULL)
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC
LIMIT 100;
