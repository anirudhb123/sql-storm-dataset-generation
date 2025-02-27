WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mk.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(mk.keyword) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    GROUP BY 
        a.id, a.title, a.production_year, c.name, ct.kind
)

SELECT 
    rm.movie_title,
    rm.production_year,
    rm.company_name,
    rm.company_type,
    CASE 
        WHEN rm.keyword_count >= 5 THEN 'High Keywords'
        WHEN rm.keyword_count BETWEEN 3 AND 4 THEN 'Medium Keywords'
        ELSE 'Low Keywords'
    END AS keyword_classification
FROM 
    ranked_movies rm
WHERE 
    rm.rank = 1
ORDER BY 
    rm.production_year DESC, 
    rm.keyword_count DESC;
