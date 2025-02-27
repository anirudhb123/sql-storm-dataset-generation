
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.id) AS rank_per_year,
        a.id AS id
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
CastRoles AS (
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
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COALESCE(CN.name, 'Unknown') AS company_name,
        CT.kind AS company_type
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name CN ON mc.company_id = CN.id
    LEFT JOIN 
        company_type CT ON mc.company_type_id = CT.id
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS unique_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    cr.total_cast,
    cr.cast_names,
    ci.company_name,
    ci.company_type,
    ks.unique_keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CastRoles cr ON rm.id = cr.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.id = ci.movie_id
LEFT JOIN 
    KeywordStats ks ON rm.id = ks.movie_id
WHERE 
    rm.rank_per_year <= 5 AND 
    (ks.unique_keywords IS NULL OR ks.unique_keywords > 3)
ORDER BY 
    rm.production_year DESC, rm.movie_title;
