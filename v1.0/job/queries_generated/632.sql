WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
KeywordCounts AS (
    SELECT 
        m.movie_id,
        COUNT(k.id) AS keyword_count
    FROM 
        movie_keyword k
    JOIN 
        aka_title m ON k.movie_id = m.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN tm.cast_count > 10 THEN 'Large Cast'
        WHEN tm.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordCounts kc ON tm.movie_id = kc.movie_id
ORDER BY 
    tm.production_year DESC,
    tm.cast_count DESC
LIMIT 10;
