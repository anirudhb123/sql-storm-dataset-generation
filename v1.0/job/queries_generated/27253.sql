WITH movie_roles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        r.role AS role_type,
        COUNT(c.id) AS role_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_role_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        a.name, t.title, t.production_year, r.role 
    HAVING 
        COUNT(c.id) > 1
),
top_movies AS (
    SELECT 
        movie_title,
        production_year,
        SUM(role_count) AS total_roles
    FROM 
        movie_roles
    GROUP BY 
        movie_title, production_year
    ORDER BY 
        total_roles DESC
    LIMIT 10
)
SELECT 
    tm.movie_title,
    tm.production_year,
    STRING_AGG(DISTINCT mr.actor_name ORDER BY mr.actor_name) AS cast_members,
    COUNT(DISTINCT mr.actor_name) AS num_unique_cast
FROM 
    top_movies tm
JOIN 
    movie_roles mr ON tm.movie_title = mr.movie_title AND tm.production_year = mr.production_year
GROUP BY 
    tm.movie_title, tm.production_year
ORDER BY 
    tm.production_year DESC;
