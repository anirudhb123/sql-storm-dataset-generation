WITH movie_details AS (
    SELECT 
        t.title, 
        t.production_year, 
        a.name AS actor_name, 
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, a.name
)
SELECT 
    md.title, 
    md.production_year, 
    COUNT(DISTINCT a.id) AS num_actors, 
    COUNT(DISTINCT comp.id) AS num_companies
FROM 
    movie_details md
LEFT JOIN 
    complete_cast cc ON md.title = cc.title
LEFT JOIN 
    movie_companies comp ON cc.movie_id = comp.movie_id
GROUP BY 
    md.title, md.production_year
HAVING 
    num_actors > 5 AND num_companies > 2
ORDER BY 
    md.production_year DESC, num_actors DESC;
