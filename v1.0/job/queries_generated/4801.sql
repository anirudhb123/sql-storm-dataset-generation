WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
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
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = (SELECT title FROM aka_title WHERE id IN (SELECT movie_id FROM movie_info WHERE movie_id = tm.title LIMIT 1))
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
