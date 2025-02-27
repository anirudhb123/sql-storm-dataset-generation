WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
)
SELECT 
    tm.title,
    COALESCE(ci.note, 'No notes available') AS role_note,
    COUNT(DISTINCT c.person_id) as total_cast,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = tm.movie_id) AS keyword_count
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    info_type it ON c.note IS NOT NULL AND it.id = c.person_role_id
WHERE 
    (tm.production_year BETWEEN 2000 AND 2020 OR tm.cast_count > 5)
GROUP BY 
    tm.movie_id, tm.title, ci.note
HAVING 
    COUNT(DISTINCT c.person_id) > 2 
ORDER BY 
    keyword_count DESC, total_cast DESC
LIMIT 10;
