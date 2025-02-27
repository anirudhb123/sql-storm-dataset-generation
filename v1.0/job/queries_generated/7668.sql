WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        a.name AS actor_name,
        k.keyword AS movie_keyword
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND c.country_code = 'USA'
)
SELECT 
    movie_title,
    production_year,
    COUNT(DISTINCT actor_name) AS actor_count,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
FROM 
    movie_details
GROUP BY 
    movie_title, production_year
ORDER BY 
    production_year DESC, actor_count DESC
LIMIT 100;
