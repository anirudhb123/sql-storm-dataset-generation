WITH RECURSIVE ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv movie'))
),
TopMovies AS (
    SELECT 
        actor_id,
        actor_name,
        movie_title,
        production_year
    FROM 
        ActorMovies
    WHERE 
        rn <= 5
)
SELECT 
    a.actor_name,
    COALESCE(COUNT(DISTINCT m.movie_id), 0) AS total_movies,
    STRING_AGG(t.movie_title, ', ') AS top_movies,
    AVG(CASE WHEN i.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') THEN CAST(i.info AS NUMERIC) ELSE NULL END) AS avg_budget,
    MAX(CASE WHEN k.keyword = 'Action' THEN 1 ELSE 0 END) AS has_action_keyword
FROM 
    aka_name a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_info i ON t.id = i.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    a.actor_name
HAVING 
    COUNT(DISTINCT t.id) > 10
ORDER BY 
    total_movies DESC, a.actor_name;
