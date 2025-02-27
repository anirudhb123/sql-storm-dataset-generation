WITH RankedMovies AS (
    SELECT 
        mt.title, 
        mt.production_year, 
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL 
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
FilteredMovies AS (
    SELECT 
        title, 
        production_year, 
        cast_count 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieInfo AS (
    SELECT 
        fm.title, 
        fm.production_year, 
        mi.info
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_info mi ON fm.production_year = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Award%')
)
SELECT 
    fm.title, 
    fm.production_year, 
    COALESCE(mi.info, 'No Awards') AS award_info,
    CASE 
        WHEN fm.cast_count > 10 THEN 'Large Cast'
        WHEN fm.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieInfo mi ON fm.title = mi.title AND fm.production_year = mi.production_year
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
