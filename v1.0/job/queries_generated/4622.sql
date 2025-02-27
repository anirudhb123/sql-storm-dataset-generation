WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(cd.company_name, 'Independent') AS company_name,
    COALESCE(cd.company_type, 'N/A') AS company_type,
    rm.cast_count,
    kc.keyword_count,
    CASE 
        WHEN rm.rank = 1 THEN 'Highest Cast'
        WHEN rm.cast_count > 5 THEN 'Above Average Cast'
        ELSE 'Standard Cast'
    END AS cast_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.title = cd.movie_id
LEFT JOIN 
    KeywordCounts kc ON rm.title = kc.movie_id
WHERE 
    rm.cast_count IS NOT NULL
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
