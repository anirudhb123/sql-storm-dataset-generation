WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS cast_count
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
    tm.production_year,
    COALESCE(GROUP_CONCAT(DISTINCT ak.name), 'No Cast') AS actors,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year
HAVING 
    COUNT(DISTINCT ak.name) > 0
ORDER BY 
    tm.production_year DESC, tm.title ASC;
