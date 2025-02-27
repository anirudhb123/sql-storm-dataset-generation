WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(CAST.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info CAST ON t.id = CAST.movie_id
    GROUP BY 
        t.id
    HAVING 
        COUNT(CAST.id) > 5
), FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        aka_names
    FROM 
        RankedMovies
    WHERE 
        production_year BETWEEN 2000 AND 2020
), MovieKeywords AS (
    SELECT 
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        FilteredMovies m
    JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.aka_names,
    mk.keywords
FROM 
    FilteredMovies fm
JOIN 
    MovieKeywords mk ON fm.title = mk.title
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
