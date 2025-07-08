
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
        a.title, a.production_year
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
        m.title,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.title ORDER BY k.keyword) AS keyword_rank
    FROM 
        TopMovies m
    JOIN 
        movie_keyword mk ON m.title = (SELECT title FROM aka_title WHERE id = mk.movie_id) 
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(mk.keyword, 'No Keywords') AS keyword,
    CASE 
        WHEN t.production_year IS NULL THEN 'Unknown Year' 
        ELSE CAST(t.production_year AS VARCHAR)
    END AS year_display
FROM 
    TopMovies t
LEFT JOIN 
    MovieKeywords mk ON t.title = mk.title AND mk.keyword_rank = 1
ORDER BY 
    t.production_year DESC, 
    t.cast_count DESC;
