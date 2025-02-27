WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        a.title, t.production_year, c.name
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        company_name,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.company_name,
    tm.cast_count,
    GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS aka_names
FROM 
    TopMovies tm
LEFT JOIN 
    aka_name ak ON ak.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title AND production_year = tm.production_year LIMIT 1))
GROUP BY 
    tm.movie_title, tm.production_year, tm.company_name, tm.cast_count
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
