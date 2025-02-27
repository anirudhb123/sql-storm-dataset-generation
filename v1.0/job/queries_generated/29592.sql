WITH actor_movie_ranks AS (
    SELECT 
        a.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
),
top_actors AS (
    SELECT 
        actor_name,
        movie_count
    FROM 
        actor_movie_ranks
    WHERE 
        actor_rank <= 10
),
movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    ta.actor_name,
    COUNT(DISTINCT md.movie_title) AS total_movies,
    ARRAY_AGG(DISTINCT md.movie_title) AS movie_titles,
    ARRAY_AGG(DISTINCT md.keyword) AS keywords,
    AVG(CASE WHEN md.production_year IS NOT NULL THEN md.production_year ELSE NULL END) AS avg_production_year
FROM 
    top_actors ta
JOIN 
    cast_info ci ON ta.actor_name = (SELECT name FROM aka_name WHERE person_id = ci.person_id)
JOIN 
    movie_details md ON ci.movie_id = (SELECT id FROM title WHERE title = md.movie_title)
GROUP BY 
    ta.actor_name
ORDER BY 
    total_movies DESC;
