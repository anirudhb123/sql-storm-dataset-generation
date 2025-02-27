WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tmk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN tm.cast_count > 10 THEN 'Large Cast'
        WHEN tm.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    (SELECT AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) 
     FROM cast_info ci 
     WHERE ci.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)) AS avg_cast_note
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords tmk ON tm.title = (SELECT title FROM aka_title WHERE id = tmk.movie_id LIMIT 1)
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
