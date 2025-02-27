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
),
CombinedResults AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.cast_count,
        COALESCE(mk.keywords, 'No keywords') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
)
SELECT 
    cr.title,
    cr.production_year,
    cr.cast_count,
    cr.keywords,
    CASE 
        WHEN cr.cast_count IS NOT NULL THEN 'Has cast' 
        ELSE 'No cast' 
    END AS cast_status
FROM 
    CombinedResults cr
WHERE 
    cr.production_year >= 2000
ORDER BY 
    cr.production_year DESC, cr.cast_count DESC;
