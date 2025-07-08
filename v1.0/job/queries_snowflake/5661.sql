
WITH ranked_titles AS (
    SELECT 
        t.title, 
        t.production_year, 
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        k.keyword LIKE 'Action%'
), 
top_action_titles AS (
    SELECT 
        title, 
        production_year, 
        actor_name 
    FROM 
        ranked_titles 
    WHERE 
        rn <= 5
)
SELECT 
    tt.production_year,
    COUNT(tt.title) AS num_titles,
    LISTAGG(tt.actor_name, ', ') WITHIN GROUP (ORDER BY tt.actor_name) AS notable_actors
FROM 
    top_action_titles tt
GROUP BY 
    tt.production_year
ORDER BY 
    tt.production_year DESC;
