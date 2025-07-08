
WITH movie_actor_counts AS (
    SELECT 
        a.name AS actor_name,
        COUNT(ci.movie_id) AS num_movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
    HAVING 
        COUNT(ci.movie_id) > 5
), movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        LISTAGG(DISTINCT g.keyword, ',') AS genres
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword g ON mk.keyword_id = g.id
    GROUP BY 
        t.title, t.production_year
), actor_movie_info AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.nr_order) AS role_count,
        LISTAGG(DISTINCT r.role, ',') AS roles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        a.name, t.title, t.production_year
)

SELECT 
    am.actor_name,
    COUNT(DISTINCT am.movie_title) AS total_movies,
    LISTAGG(DISTINCT am.movie_title, ',') AS movie_list,
    AVG(am.role_count) AS avg_roles_per_movie,
    md.genres
FROM 
    actor_movie_info am
JOIN 
    movie_details md ON am.movie_title = md.movie_title
JOIN 
    movie_actor_counts ac ON am.actor_name = ac.actor_name
GROUP BY 
    am.actor_name, md.genres
ORDER BY 
    total_movies DESC
LIMIT 10;
