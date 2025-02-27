WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
DistinctKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        t.title,
        COALESCE(dk.keywords, 'No Keywords') AS keywords,
        rm.cast_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        DistinctKeywords dk ON rm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id LIMIT 1)
    WHERE 
        rm.rank <= 5
)
SELECT 
    md.title,
    md.keywords,
    md.cast_count
FROM 
    MovieDetails md
ORDER BY 
    md.cast_count DESC;
