
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title, 
        a.production_year, 
        COUNT(c.id) AS cast_count, 
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, 
        a.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_title, 
        rm.production_year, 
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
),
MovieKeywords AS (
    SELECT 
        m.movie_id, 
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
FinalResults AS (
    SELECT 
        tm.movie_title, 
        tm.production_year, 
        COALESCE(mk.keywords, 'No keywords') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        aka_title a ON tm.movie_title = a.title AND tm.production_year = a.production_year
    LEFT JOIN 
        MovieKeywords mk ON a.id = mk.movie_id
)
SELECT 
    movie_title AS title, 
    production_year, 
    keywords 
FROM 
    FinalResults 
WHERE 
    keywords NOT LIKE '%action%'
ORDER BY 
    production_year DESC;
