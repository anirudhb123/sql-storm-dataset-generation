WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyRoles AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT c.id) AS total_companies,
        MAX(cn.name) AS main_company_name
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
CastCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cc.total_cast, 0) AS total_cast,
    COALESCE(cc.cast_names, 'No Cast') AS cast_names,
    COALESCE(cr.total_companies, 0) AS total_companies,
    COALESCE(cr.main_company_name, 'No Company') AS main_company_name,
    AVG(cc.total_cast) OVER () AS avg_cast_per_movie
FROM 
    RankedMovies rm
LEFT JOIN 
    CastCounts cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    CompanyRoles cr ON rm.movie_id = cr.movie_id
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
