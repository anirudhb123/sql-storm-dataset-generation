WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastCounts AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS cast_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MoviesWithDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cc.cast_count, 0) AS cast_count,
        ci.company_name,
        ci.company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastCounts cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        CompanyInfo ci ON rm.movie_id = ci.movie_id
)
SELECT 
    m.title,
    m.production_year,
    m.cast_count,
    STRING_AGG(DISTINCT m.company_name, ', ') AS companies,
    COUNT(DISTINCT m.company_type) AS unique_company_types
FROM 
    MoviesWithDetails m
WHERE 
    m.cast_count > 0
GROUP BY 
    m.title, m.production_year, m.cast_count
HAVING 
    COUNT(DISTINCT m.company_name) > 1
ORDER BY 
    m.production_year DESC, m.title
LIMIT 10;
