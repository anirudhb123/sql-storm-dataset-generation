
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)

SELECT 
    tm.title,
    tm.production_year,
    COALESCE(
        (SELECT LISTAGG(a.name, ', ') 
         FROM aka_name a 
         JOIN cast_info ci ON a.person_id = ci.person_id 
         WHERE ci.movie_id IN (SELECT movie_id FROM movie_companies mc WHERE mc.company_type_id IS NOT NULL) 
         GROUP BY ci.movie_id 
         HAVING ci.movie_id = (SELECT movie_id FROM complete_cast WHERE subject_id IN (SELECT id FROM name WHERE name LIKE '%Smith%'))), 
        'No actors found') AS actors
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.title = mi.info
WHERE 
    tm.production_year >= (SELECT MAX(production_year) - 5 FROM aka_title)
ORDER BY 
    tm.production_year DESC;
