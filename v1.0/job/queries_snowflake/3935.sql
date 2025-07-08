WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
CastCounts AS (
    SELECT 
        c.movie_id,
        COUNT(*) AS total_cast
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        COALESCE(c.name, 'Unknown Company') AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    LEFT JOIN 
        company_name c ON m.company_id = c.id 
    LEFT JOIN 
        company_type ct ON m.company_type_id = ct.id
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cc.total_cast, 0) AS total_cast,
    COALESCE(ci.company_name, 'No Company') AS company_name,
    COALESCE(ci.company_type, 'No Type') AS company_type,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN rm.rank <= 3 THEN 'Top Release'
        ELSE 'Older Release'
    END AS release_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CastCounts cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    KeywordCounts kc ON rm.movie_id = kc.movie_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, 
    total_cast DESC, 
    rm.title ASC;
