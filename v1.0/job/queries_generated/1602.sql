WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS year_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        mt.title, mt.production_year
), 
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        year_rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    ak.name AS actor_name,
    ci.note AS actor_note,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    AVG(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) AS has_info
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON ci.movie_id IN (SELECT movie_id FROM complete_cast WHERE subject_id IN (SELECT person_id FROM aka_name WHERE name LIKE '%Smith%'))
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id IN (SELECT id FROM aka_title WHERE title = tm.title)
LEFT JOIN 
    movie_info mi ON mi.movie_id IN (SELECT id FROM aka_title WHERE title = tm.title)
GROUP BY 
    tm.title, tm.production_year, ak.name, ci.note
HAVING 
    COUNT(DISTINCT mk.keyword) > 3 OR has_info > 0
ORDER BY 
    tm.production_year DESC, keyword_count DESC;
