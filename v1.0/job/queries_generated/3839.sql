WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title a 
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
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
        rm.rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.title,
        string_agg(k.keyword, ', ') AS keywords
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON m.title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.title
WHERE 
    tm.production_year IS NOT NULL 
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
