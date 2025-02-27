
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title AS top_movie,
    tm.production_year,
    COALESCE(ki.keyword, 'No Keywords') AS keyword,
    STRING_AGG(DISTINCT a.name, ', ') AS actors
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE movie_id = mk.movie_id LIMIT 1)
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    complete_cast cc ON tm.title = (SELECT title FROM aka_title WHERE movie_id = cc.movie_id LIMIT 1)
LEFT JOIN 
    aka_name a ON cc.subject_id = a.person_id
WHERE 
    tm.cast_count > 3 AND 
    (tm.production_year IS NOT NULL AND tm.production_year > 2000)
GROUP BY 
    tm.title, tm.production_year, ki.keyword
ORDER BY 
    tm.production_year DESC, top_movie;
