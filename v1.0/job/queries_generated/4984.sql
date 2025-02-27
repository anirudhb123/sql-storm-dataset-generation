WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
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
MovieKeywords AS (
    SELECT 
        m.title, 
        kv.keyword
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON m.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    LEFT JOIN 
        keyword kv ON mk.keyword_id = kv.id
)
SELECT 
    tk.title,
    tk.production_year,
    tk.cast_count,
    STRING_AGG(mk.keyword, ', ') AS keywords
FROM 
    TopMovies tk
LEFT JOIN 
    MovieKeywords mk ON tk.title = mk.title
GROUP BY 
    tk.title, tk.production_year, tk.cast_count
ORDER BY 
    tk.production_year DESC, 
    tk.cast_count DESC;
