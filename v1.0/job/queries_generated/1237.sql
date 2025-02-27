WITH YearlyProduction AS (
    SELECT 
        a.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS total_cast_members 
    FROM 
        aka_title t 
    JOIN 
        title a ON t.movie_id = a.id 
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id 
    GROUP BY 
        a.title, t.production_year
), 
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        total_cast_members,
        RANK() OVER (PARTITION BY production_year ORDER BY total_cast_members DESC) AS rank
    FROM 
        YearlyProduction
)
SELECT 
    t.title,
    t.production_year,
    t.total_cast_members,
    (SELECT AVG(total_cast_members) FROM TopMovies WHERE production_year = t.production_year) AS avg_cast_members,
    COALESCE(c.company_name, 'Unknown') AS production_company
FROM 
    TopMovies t
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = t.title AND production_year = t.production_year LIMIT 1)
LEFT JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    t.rank <= 5
ORDER BY 
    t.production_year, t.total_cast_members DESC;
