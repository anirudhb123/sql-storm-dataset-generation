WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
KeywordCounts AS (
    SELECT 
        m.movie_id, 
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
TopMovies AS (
    SELECT 
        rm.title, 
        rm.production_year 
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COALESCE(p.info, 'No Info') AS director_info
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordCounts kc ON kc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
LEFT JOIN 
    (SELECT DISTINCT c.movie_id, pi.info 
     FROM complete_cast c
     JOIN person_info pi ON c.subject_id = pi.person_id
     WHERE pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Director') AND pi.note IS NOT NULL) AS p 
ON 
    p.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
WHERE 
    tm.production_year BETWEEN 2000 AND 2020
ORDER BY 
    tm.production_year DESC, 
    keyword_count DESC;
