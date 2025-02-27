WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_by_cast <= 5
),
KeywordCounts AS (
    SELECT 
        m.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id
)
SELECT 
    tm.title,
    tm.production_year,
    kc.keyword_count,
    coalesce(kc.keyword_count, 0) + COALESCE(cm.total_companies, 0) AS combined_count,
    CASE 
        WHEN tm.production_year IS NULL THEN 'Unknown Year' 
        ELSE CAST(tm.production_year AS TEXT) 
    END AS display_year
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordCounts kc ON tm.title = kc.movie_id
LEFT JOIN (
    SELECT 
        movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
) cm ON tm.title = cm.movie_id
WHERE 
    (kc.keyword_count IS NOT NULL OR cm.total_companies IS NOT NULL)
ORDER BY 
    display_year DESC, 
    combined_count DESC;
