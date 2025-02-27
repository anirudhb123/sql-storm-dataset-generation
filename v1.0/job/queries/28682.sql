
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        ak.name AS director_name,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast_count
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.title, t.production_year, ak.name, t.kind_id
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        director_name, 
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast_count <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.director_name,
    tm.cast_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT c.name, ', ') AS companies
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
LEFT JOIN 
    company_name c ON c.id = mc.company_id
GROUP BY 
    tm.title, tm.production_year, tm.director_name, tm.cast_count
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
