
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rn
    FROM 
        aka_title m
    WHERE 
        m.kind_id = 1
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
CastAggregates AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT p.name, ', ') WITHIN GROUP (ORDER BY p.name) AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
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
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ka.keyword_count, 0) AS keyword_count,
    COALESCE(ca.cast_count, 0) AS cast_count,
    ca.cast_names,
    ARRAY_AGG(DISTINCT ci.company_name) AS companies,
    COUNT(DISTINCT ci.company_type) AS distinct_company_types
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywordCounts ka ON rm.movie_id = ka.movie_id
LEFT JOIN 
    CastAggregates ca ON rm.movie_id = ca.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
WHERE 
    rm.rn <= 10 AND (rm.production_year IS NOT NULL OR rm.title IS NOT NULL)
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, ka.keyword_count, ca.cast_count, ca.cast_names
ORDER BY 
    rm.production_year DESC, rm.title;
