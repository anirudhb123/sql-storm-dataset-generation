WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        p.gender
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        aka_name a ON cc.subject_id = a.person_id
    JOIN 
        name p ON a.person_id = p.id
    WHERE 
        cn.country_code = 'USA'
        AND t.production_year > 2000
    ORDER BY 
        t.production_year DESC
)
SELECT 
    title_id,
    title,
    production_year,
    actor_name,
    gender
FROM 
    ranked_titles 
WHERE 
    actor_name IS NOT NULL
LIMIT 100;
