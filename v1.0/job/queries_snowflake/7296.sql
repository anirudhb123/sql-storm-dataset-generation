
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        r.role,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
recent_movies AS (
    SELECT 
        title_id,
        title,
        production_year,
        RANK() OVER (ORDER BY production_year DESC) AS year_rank
    FROM 
        ranked_titles
    WHERE 
        production_year >= 2010
)
SELECT 
    rm.title,
    rm.production_year,
    LISTAGG(rt.actor_name, ', ') WITHIN GROUP (ORDER BY rt.actor_name) AS cast,
    COUNT(DISTINCT rt.actor_name) AS num_actors
FROM 
    recent_movies rm
JOIN 
    ranked_titles rt ON rm.title_id = rt.title_id
WHERE 
    rt.actor_rank <= 3
GROUP BY 
    rm.title_id, rm.title, rm.production_year
HAVING 
    COUNT(DISTINCT rt.actor_name) >= 3
ORDER BY 
    rm.production_year DESC, rm.title;
