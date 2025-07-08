
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS num_companies,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS companies,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT m.id) DESC) AS rank_by_companies
    FROM 
        aka_title t
    JOIN 
        movie_companies m ON t.id = m.movie_id
    JOIN 
        company_name c ON m.company_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        num_companies, 
        companies
    FROM 
        RankedMovies
    WHERE 
        rank_by_companies <= 5
)
SELECT 
    tm.title AS Movie_Title,
    tm.production_year AS Production_Year,
    tm.num_companies AS Number_of_Companies,
    tm.companies AS Associated_Companies,
    ARRAY_AGG(a.name) AS Cast_Names
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.num_companies, tm.companies
ORDER BY 
    tm.production_year DESC, tm.num_companies DESC;
