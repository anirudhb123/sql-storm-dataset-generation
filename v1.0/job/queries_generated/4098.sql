WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY a.id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast c ON a.id = c.movie_id
    LEFT JOIN 
        cast_info ci ON c.subject_id = ci.id
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(SUM(mk.keyword), 'No Keywords') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id) 
GROUP BY 
    tm.title,
    tm.production_year,
    tm.cast_count
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
