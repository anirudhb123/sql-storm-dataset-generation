WITH actor_movie_data AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        kt.keyword AS movie_keyword,
        rt.role AS role_name
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
actor_movie_summary AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(DISTINCT movie_title) AS total_movies,
        STRING_AGG(DISTINCT movie_title, ', ') AS movie_titles,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT role_name, ', ') AS roles
    FROM 
        actor_movie_data
    GROUP BY 
        actor_id, actor_name
    ORDER BY 
        total_movies DESC
)
SELECT 
    ams.actor_id,
    ams.actor_name,
    ams.total_movies,
    ams.movie_titles,
    ams.keywords,
    ams.roles
FROM 
    actor_movie_summary ams
WHERE 
    ams.total_movies > 5
    AND ams.keywords IS NOT NULL
ORDER BY 
    ams.total_movies DESC;
