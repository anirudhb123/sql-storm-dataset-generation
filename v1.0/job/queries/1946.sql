WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        cast_count 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id, 
        ARRAY_AGG(DISTINCT k.keyword) AS keywords 
    FROM 
        movie_keyword m
    INNER JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    fm.movie_title, 
    fm.production_year, 
    fm.cast_count, 
    COALESCE(mk.keywords, '{}') AS keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    aka_title t ON fm.movie_title = t.title AND fm.production_year = t.production_year
LEFT JOIN 
    MovieKeywords mk ON t.id = mk.movie_id
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
