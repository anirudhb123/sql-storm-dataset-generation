WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year, k.keyword
),

TopKeywords AS (
    SELECT 
        keyword,
        COUNT(*) AS keyword_count
    FROM 
        RankedMovies
    GROUP BY 
        keyword
    ORDER BY 
        keyword_count DESC
    LIMIT 10
)

SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    tk.keyword,
    tk.keyword_count
FROM 
    RankedMovies rm
JOIN 
    TopKeywords tk ON rm.keyword = tk.keyword
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;