
WITH RankedMovies AS (
    SELECT 
        t.id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
),
KeywordCount AS (
    SELECT 
        mt.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    CONCAT('Movie: ', tm.title, ' | Year: ', tm.production_year, ' | Cast Count: ', tm.cast_count, ' | Keyword Count: ', COALESCE(kc.keyword_count, 0)) AS movie_details
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordCount kc ON kc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
