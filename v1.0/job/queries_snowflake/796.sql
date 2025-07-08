WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
CastCounts AS (
    SELECT 
        m.movie_id,
        COUNT(c.id) AS total_cast
    FROM 
        complete_cast m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    GROUP BY 
        m.movie_id
), 
KeyWordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(k.id) AS keyword_count
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(cc.total_cast, 0) AS total_cast,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN r.rank_per_year <= 5 THEN 'Top 5' 
        ELSE 'Others' 
    END AS ranking_category
FROM 
    RankedMovies r
LEFT JOIN 
    CastCounts cc ON r.movie_id = cc.movie_id
LEFT JOIN 
    KeyWordCounts kc ON r.movie_id = kc.movie_id
WHERE 
    (cc.total_cast > 10 OR kc.keyword_count > 5)
ORDER BY 
    r.production_year DESC, 
    r.title ASC
