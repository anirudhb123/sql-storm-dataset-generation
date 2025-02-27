WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS num_cast
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cc.num_cast, 0) AS total_cast,
    COALESCE(ci.num_companies, 0) AS total_companies,
    ci.company_names
FROM 
    RankedMovies rm
LEFT JOIN 
    CastCounts cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
WHERE 
    (ci.num_companies IS NULL OR ci.num_companies > 0)
    AND (rm.title_rank <= 10 OR rm.production_year >= 2000)
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
