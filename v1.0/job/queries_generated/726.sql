WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
KeywordMovies AS (
    SELECT 
        m.title AS movie_title,
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
    GROUP BY 
        m.title, k.keyword
)
SELECT 
    tm.movie_title,
    tm.production_year,
    COALESCE(MAX(km.keyword_count), 0) AS max_keyword_count,
    STRING_AGG(DISTINCT km.keyword, ', ') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordMovies km ON tm.movie_title = km.movie_title
GROUP BY 
    tm.movie_title, tm.production_year
ORDER BY 
    tm.production_year DESC, max_keyword_count DESC;
