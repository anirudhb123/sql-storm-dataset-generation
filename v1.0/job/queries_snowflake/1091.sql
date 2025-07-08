WITH ranked_movies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.title, mt.production_year
),
top_years AS (
    SELECT 
        production_year, 
        MAX(total_companies) AS max_companies
    FROM 
        ranked_movies
    GROUP BY 
        production_year
)
SELECT 
    rm.title,
    rm.production_year,
    rm.total_companies,
    CASE 
        WHEN rm.total_companies IS NULL THEN 'No Companies'
        ELSE 'Companies Present' 
    END AS company_presence,
    ARRAY_AGG(DISTINCT pa.name) AS actor_names
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_info ci ON rm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id LIMIT 1)
LEFT JOIN 
    aka_name pa ON ci.person_id = pa.person_id
WHERE 
    rm.production_year IN (SELECT production_year FROM top_years WHERE max_companies > 2)
GROUP BY 
    rm.title, rm.production_year, rm.total_companies
HAVING 
    COUNT(DISTINCT ci.person_id) >= 3
ORDER BY 
    rm.production_year DESC, rm.total_companies DESC;
