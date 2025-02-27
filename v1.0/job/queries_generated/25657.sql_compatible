
WITH actor_count AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.person_id
),

popular_actors AS (
    SELECT 
        a.id,
        a.name,
        ac.movie_count
    FROM 
        aka_name a
    JOIN 
        actor_count ac ON a.person_id = ac.person_id
    WHERE 
        ac.movie_count > 5
),

movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
)

SELECT 
    p.name AS actor_name,
    COUNT(DISTINCT md.movie_id) AS num_movies,
    STRING_AGG(DISTINCT md.title, ', ') AS movies,
    STRING_AGG(DISTINCT md.keyword, ', ') AS keywords
FROM 
    popular_actors p
JOIN 
    cast_info ci ON p.id = ci.person_id
JOIN 
    movie_details md ON ci.movie_id = md.movie_id
GROUP BY 
    p.id, p.name
ORDER BY 
    num_movies DESC
LIMIT 10;
