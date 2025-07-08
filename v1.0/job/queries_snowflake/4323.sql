
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn,
        COUNT(c.person_id) OVER (PARTITION BY a.id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        a.production_year IS NOT NULL
        AND a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)

SELECT 
    rm.title,
    rm.production_year,
    COALESCE LISTAGG(p.name, ', ') WITHIN GROUP (ORDER BY p.name), 'No Cast') AS cast_names,
    rm.cast_count
FROM 
    RankedMovies rm
LEFT JOIN 
    complete_cast cc ON rm.title = COALESCE((SELECT title FROM aka_title WHERE id = cc.movie_id), 'Unknown Title')
LEFT JOIN 
    cast_info c ON cc.subject_id = c.id
LEFT JOIN 
    aka_name p ON c.person_id = p.person_id
WHERE 
    rm.rn <= 5
GROUP BY 
    rm.title, rm.production_year, rm.cast_count
HAVING 
    COUNT(c.person_id) > 0
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
