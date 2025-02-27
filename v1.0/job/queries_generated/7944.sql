WITH ranked_movies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS ranking
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')
),
movie_details AS (
    SELECT 
        rm.actor_id,
        rm.actor_name,
        rm.movie_title,
        rm.production_year,
        mc.company_id,
        cn.name AS company_name,
        mt.kind AS company_type
    FROM 
        ranked_movies rm
    JOIN 
        complete_cast cc ON rm.movie_title = (SELECT title FROM title WHERE id = cc.movie_id)
    JOIN 
        movie_companies mc ON cc.movie_id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type mt ON mc.company_type_id = mt.id
    WHERE 
        rm.ranking <= 5
)
SELECT 
    actor_id, 
    actor_name, 
    COUNT(movie_title) AS movie_count,
    ARRAY_AGG(DISTINCT movie_title) AS movie_list,
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', ', ') AS companies_involved
FROM 
    movie_details
GROUP BY 
    actor_id, actor_name
ORDER BY 
    movie_count DESC;
