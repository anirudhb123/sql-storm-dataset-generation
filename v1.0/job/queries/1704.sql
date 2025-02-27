WITH RankedMovies AS (
    SELECT 
        mt.title, 
        mt.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title mt 
    JOIN 
        cast_info c ON mt.id = c.movie_id 
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
FilteredMovies AS (
    SELECT 
        m.title, 
        m.production_year, 
        m.cast_count 
    FROM 
        RankedMovies m 
    WHERE 
        m.rank <= 5
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(ARRAY_AGG(DISTINCT ak.name), '{}') AS aliases,
    COALESCE(STRING_AGG(DISTINCT pi.info, '; '), 'No info available') AS person_info
FROM 
    FilteredMovies fm 
LEFT JOIN 
    cast_info c ON c.movie_id = (SELECT id FROM aka_title WHERE title = fm.title AND production_year = fm.production_year LIMIT 1)
LEFT JOIN 
    aka_name ak ON ak.person_id = c.person_id 
LEFT JOIN 
    person_info pi ON pi.person_id = c.person_id 
WHERE 
    fm.production_year IS NOT NULL
GROUP BY 
    fm.title, fm.production_year
ORDER BY 
    fm.production_year DESC, fm.title;
