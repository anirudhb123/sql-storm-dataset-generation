
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(cc.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(cc.id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
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
        rn <= 5
),
KeywordCounts AS (
    SELECT 
        m.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    INNER JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN kc.keyword_count > 10 THEN 'Highly Tagged'
        WHEN kc.keyword_count IS NULL THEN 'No Tags'
        ELSE 'Moderately Tagged'
    END AS tag_status
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordCounts kc ON tm.title = (SELECT DISTINCT title FROM aka_title WHERE id = kc.movie_id AND production_year = tm.production_year)
ORDER BY 
    tm.production_year, tag_status DESC;
