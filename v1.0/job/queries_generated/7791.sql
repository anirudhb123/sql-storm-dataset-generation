WITH ranked_movies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    WHERE 
        a.name IS NOT NULL
), 
actor_movie_count AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count
    FROM 
        ranked_movies
    WHERE 
        rn = 1
    GROUP BY 
        actor_id, actor_name
)
SELECT 
    amc.actor_name,
    amc.movie_count,
    t.title,
    t.production_year,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keyword_list
FROM 
    actor_movie_count amc
JOIN 
    cast_info c ON amc.actor_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    amc.actor_name, amc.movie_count, t.title, t.production_year
ORDER BY 
    amc.movie_count DESC, t.production_year DESC;
