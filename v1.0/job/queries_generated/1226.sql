WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        title t
        LEFT JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.title,
        k.keyword
    FROM 
        TopMovies m
        LEFT JOIN movie_keyword mk ON m.title = (SELECT t.title FROM title t WHERE t.id = m.id)
        LEFT JOIN keyword k ON mk.keyword_id = k.id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(k.keyword, 'No Keywords') AS keyword,
    STRING_AGG(DISTINCT k.keyword, ', ') AS all_keywords
FROM 
    TopMovies m
LEFT JOIN 
    MovieKeywords k ON m.title = k.title
GROUP BY 
    m.title, m.production_year
ORDER BY 
    m.production_year DESC, m.title;
