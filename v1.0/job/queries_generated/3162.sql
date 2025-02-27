WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS movie_rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.movie_rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    AVG(pi.info IS NOT NULL) AS avg_person_info
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.title = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id
GROUP BY 
    tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, total_cast DESC
FETCH FIRST 10 ROWS ONLY;
