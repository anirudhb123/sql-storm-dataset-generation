
WITH movie_cast AS (
    SELECT 
        ct.kind AS role_type,
        tk.title AS movie_title,
        tk.production_year,
        ak.name AS actor_name,
        ak.id AS actor_id,
        COUNT(*) AS role_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title tk ON ci.movie_id = tk.id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        ct.kind, tk.title, tk.production_year, ak.name, ak.id
), top_actors AS (
    SELECT 
        actor_id, 
        actor_name, 
        SUM(role_count) AS total_roles
    FROM 
        movie_cast
    GROUP BY 
        actor_id, actor_name
    ORDER BY 
        total_roles DESC
    LIMIT 10
)
SELECT 
    ta.actor_name,
    COUNT(DISTINCT mc.movie_title) AS movies_count,
    STRING_AGG(DISTINCT mc.movie_title, '; ') AS movie_titles,
    STRING_AGG(DISTINCT mc.role_type, '; ') AS roles
FROM 
    top_actors ta
JOIN 
    movie_cast mc ON ta.actor_id = mc.actor_id
GROUP BY 
    ta.actor_id, ta.actor_name
ORDER BY 
    movies_count DESC;
