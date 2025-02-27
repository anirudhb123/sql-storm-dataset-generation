WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE
        a.production_year IS NOT NULL
)
SELECT 
    rm.production_year,
    COUNT(*) AS total_movies,
    STRING_AGG(DISTINCT rm.title, ', ') AS titles,
    STRING_AGG(DISTINCT rm.company_name, ', ') AS companies,
    STRING_AGG(DISTINCT rm.movie_keyword, ', ') AS keywords
FROM 
    ranked_movies rm
WHERE 
    rm.year_rank <= 5  
GROUP BY 
    rm.production_year
ORDER BY 
    rm.production_year DESC;