WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank,
        COUNT(ct.id) OVER (PARTITION BY mt.id) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    WHERE 
        mt.production_year IS NOT NULL
),

FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.title_rank <= 5
        AND rm.cast_count > 2
),

MovieInfo AS (
    SELECT 
        fm.movie_id,
        GROUP_CONCAT(mi.info) AS movie_info,
        MAX(mi.note) AS last_note
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_info mi ON fm.movie_id = mi.movie_id
    GROUP BY 
        fm.movie_id
)

SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_count,
    COALESCE(mi.movie_info, 'No Information') AS movie_details,
    COALESCE(mi.last_note, 'No Note') AS note_details,
    CASE 
        WHEN fm.cast_count IS NULL THEN 'Unknown'
        WHEN fm.cast_count < 5 THEN 'Limited Cast'
        ELSE 'Rich Cast'
    END AS cast_description
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieInfo mi ON fm.movie_id = mi.movie_id
WHERE 
    fm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    fm.production_year DESC,
    fm.title;

-- Additional complex logic to filter out movies with the same name but different IDs:
UNION ALL
SELECT 
    DISTINCT mt.id AS movie_id,
    mt.title,
    mt.production_year,
    NULL AS cast_count,
    'Duplicate Title Filtered' AS movie_info,
    'Not Applicable' AS last_note,
    'Duplicate Title in Results' AS cast_description
FROM 
    aka_title mt
WHERE 
    mt.title IN (SELECT title FROM aka_title GROUP BY title HAVING COUNT(*) > 1)
ORDER BY 
    production_year DESC, 
    title;

-- Note: The above logic might yield an additional result set for duplicate movie titles
-- in the year range provided, demonstrating usage of UNION ALL
