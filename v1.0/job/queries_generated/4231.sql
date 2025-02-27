WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) as rank
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
), 
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
), 
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COALESCE(cc.company_count, 0) AS company_count,
    rm.cast_count
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordCounts kc ON rm.rank = 1 AND kc.movie_id = rm.id
LEFT JOIN 
    CompanyCounts cc ON cc.movie_id = rm.id
WHERE 
    rm.production_year >= 2000 AND rm.cast_count IS NOT NULL
ORDER BY 
    rm.production_year ASC, 
    rm.cast_count DESC;
