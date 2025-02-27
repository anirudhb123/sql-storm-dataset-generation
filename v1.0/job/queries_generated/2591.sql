WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) as cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) as rank
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) as company_rank
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) as keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    cd.company_name,
    cd.company_type,
    kc.keyword_count,
    COALESCE(cd.company_rank, 'No Company') as company_order,
    CASE 
        WHEN rm.cast_count IS NULL THEN 'No Cast'
        ELSE 'Has Cast'
    END as cast_status
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.title = cd.movie_name AND cd.company_rank = 1
LEFT JOIN 
    KeywordCount kc ON rm.title_id = kc.movie_id
WHERE
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC
LIMIT 50;
