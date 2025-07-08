WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
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
        rank_by_cast <= 5
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN tm.cast_count > 10 THEN 'Large Cast' 
        WHEN tm.cast_count > 5 THEN 'Medium Cast' 
        ELSE 'Small Cast' 
    END AS cast_size,
    CASE 
        WHEN kc.keyword_count IS NULL THEN 'No keywords' 
        ELSE 'Has keywords' 
    END AS keyword_status
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordCount kc ON tm.movie_id = kc.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
