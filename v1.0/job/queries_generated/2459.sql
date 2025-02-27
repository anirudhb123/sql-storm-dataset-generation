WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id
    LEFT JOIN 
        role_type rt ON c.role_id = rt.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        t.production_year IS NOT NULL AND
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, cast_count, has_note
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    tm.title,
    COALESCE(GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name), 'No Cast') AS cast_names,
    CASE 
        WHEN pm.info IS NOT NULL THEN pm.info 
        ELSE 'No additional info available' 
    END AS additional_info
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info c ON tm.movie_id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_info pm ON tm.movie_id = pm.movie_id
WHERE 
    pm.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
GROUP BY 
    tm.movie_id, tm.title, pm.info
ORDER BY 
    tm.cast_count DESC;
