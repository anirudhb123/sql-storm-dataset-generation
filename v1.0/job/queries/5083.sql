WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        c.name AS company_name,
        count(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        a.title, a.production_year, c.name
),
most_frequent_titles AS (
    SELECT 
        title, 
        production_year,
        RANK() OVER (PARTITION BY production_year ORDER BY company_count DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    m.title, 
    m.production_year, 
    m.company_name, 
    m.company_count
FROM 
    ranked_movies m
JOIN 
    most_frequent_titles mt ON m.title = mt.title AND m.production_year = mt.production_year
WHERE 
    mt.rank <= 5
ORDER BY 
    m.production_year DESC, 
    m.company_count DESC;
