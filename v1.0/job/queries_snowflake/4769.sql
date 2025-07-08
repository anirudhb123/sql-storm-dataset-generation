
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(kc.keyword_count, 0) AS keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordCounts kc ON kc.movie_id = (SELECT id FROM title WHERE title = rm.title AND production_year = rm.production_year)
WHERE 
    rm.rn <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
