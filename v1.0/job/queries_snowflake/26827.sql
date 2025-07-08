
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        rt.role,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        role_type rt ON ci.person_role_id = rt.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year IS NOT NULL
),

actor_statistics AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT title_id) AS movie_count,
        LISTAGG(DISTINCT title, ', ') WITHIN GROUP (ORDER BY title) AS movie_titles
    FROM 
        ranked_titles
    WHERE 
        year_rank <= 5  
    GROUP BY 
        actor_name
)

SELECT 
    a.actor_name,
    a.movie_count,
    a.movie_titles,
    (SELECT COUNT(*) FROM title t2 WHERE t2.production_year >= EXTRACT(YEAR FROM '2024-10-01'::DATE) - 10) AS recent_movies_count,
    (SELECT COUNT(DISTINCT t2.id) FROM movie_keyword mk JOIN keyword k ON mk.keyword_id = k.id JOIN title t2 ON mk.movie_id = t2.id WHERE k.keyword LIKE '%action%' AND t2.production_year >= EXTRACT(YEAR FROM '2024-10-01'::DATE) - 10) AS action_movies_count
FROM 
    actor_statistics a
ORDER BY 
    a.movie_count DESC, a.actor_name;
