WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COUNT(c.person_id) OVER (PARTITION BY a.id) AS total_cast
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.total_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.total_cast > 5 AND 
        rm.year_rank <= 10
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN fm.total_cast > 20 THEN 'Large Cast'
        WHEN fm.total_cast BETWEEN 11 AND 20 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieKeywords mk ON fm.title = mk.movie_id
ORDER BY 
    fm.production_year DESC, 
    fm.title ASC;
