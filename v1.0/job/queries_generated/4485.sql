WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(STRING_AGG(DISTINCT ak.name, ', '), 'No cast') AS cast_names,
    COALESCE(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS notes_count,
    NULLIF(AVG(CASE WHEN tm.cast_count > 0 THEN tm.cast_count ELSE NULL END), 0) AS average_cast_count
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.title = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
GROUP BY 
    tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, tm.title ASC;
