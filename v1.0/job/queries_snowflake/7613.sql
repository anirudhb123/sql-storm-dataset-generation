
WITH ranked_movies AS (
    SELECT 
        tt.title, 
        tt.production_year, 
        an.name AS actor_name, 
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM 
        aka_title tt
    JOIN 
        complete_cast cc ON tt.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON tt.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        tt.production_year >= 2000
    GROUP BY 
        tt.title, tt.production_year, an.name
    ORDER BY 
        keyword_count DESC
    LIMIT 10
)
SELECT 
    rm.title, 
    rm.production_year, 
    rm.actor_name,
    COUNT(DISTINCT mc.company_id) AS production_companies
FROM 
    ranked_movies rm
JOIN 
    movie_companies mc ON rm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
GROUP BY 
    rm.title, rm.production_year, rm.actor_name
ORDER BY 
    production_companies DESC;
