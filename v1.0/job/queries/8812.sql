WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT * 
    FROM RankedMovies 
    WHERE rank <= 5
)
SELECT 
    fm.title, 
    fm.production_year, 
    fm.total_cast, 
    fm.cast_names
FROM 
    FilteredMovies fm
JOIN 
    movie_info mi ON fm.title = mi.info AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
WHERE 
    mi.note IS NOT NULL
ORDER BY 
    fm.production_year DESC;
