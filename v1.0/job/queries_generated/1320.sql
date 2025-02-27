WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rnk
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
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
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN rm.cast_count = 0 THEN 'No Cast'
        WHEN rm.cast_count > 10 THEN 'Large Cast'
        ELSE 'Small Cast' 
    END AS cast_size
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.title = rm.title 
WHERE 
    rm.rnk <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
