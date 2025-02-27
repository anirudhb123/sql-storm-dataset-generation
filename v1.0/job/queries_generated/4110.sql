WITH movie_cast AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_order,
        COUNT(c.person_id) OVER (PARTITION BY t.id) AS total_actors
    FROM 
        aka_name a
    INNER JOIN 
        cast_info c ON a.person_id = c.person_id
    INNER JOIN 
        aka_title t ON c.movie_id = t.movie_id
),
top_movies AS (
    SELECT 
        movie_title,
        production_year,
        SUM(total_actors) AS total_cast_size
    FROM 
        movie_cast
    WHERE 
        production_year >= 2000
    GROUP BY 
        movie_title, production_year
    HAVING 
        SUM(total_actors) > 5
),
movie_keywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    tm.movie_title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COUNT(DISTINCT mc.actor_name) AS unique_actors,
    MAX(mc.actor_order) AS max_actor_order,
    AVG(mc.total_actors) AS avg_cast_size
FROM 
    top_movies tm
LEFT JOIN 
    movie_keywords mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title AND production_year = tm.production_year LIMIT 1)
LEFT JOIN 
    movie_cast mc ON mc.movie_title = tm.movie_title AND mc.production_year = tm.production_year
GROUP BY 
    tm.movie_title, tm.production_year
ORDER BY 
    tm.production_year DESC, 
    unique_actors DESC, 
    tm.movie_title;
