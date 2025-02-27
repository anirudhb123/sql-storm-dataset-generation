WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY MIN(c.nr_order) DESC) AS rank_within_year
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
CompanyCount AS (
    SELECT 
        mm.movie_id,
        COUNT(DISTINCT mc.company_id) AS distinct_company_count
    FROM 
        movie_companies mc
    JOIN 
        aka_title mm ON mc.movie_id = mm.id
    GROUP BY 
        mm.movie_id
),
KeywordsCount AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS distinct_keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(cc.distinct_company_count, 0) AS company_count,
    COALESCE(kc.distinct_keyword_count, 0) AS keyword_count,
    CASE 
        WHEN r.rank_within_year = 1 THEN 'Best Movie of Year'
        ELSE 'Other'
    END AS movie_category
FROM 
    RankedMovies r
LEFT JOIN 
    CompanyCount cc ON r.movie_id = cc.movie_id
LEFT JOIN 
    KeywordsCount kc ON r.movie_id = kc.movie_id
WHERE 
    (cc.distinct_company_count IS NULL OR cc.distinct_company_count > 1) 
    AND (kc.distinct_keyword_count IS NULL OR kc.distinct_keyword_count BETWEEN 1 AND 10)
ORDER BY 
    r.production_year DESC, r.rank_within_year;
