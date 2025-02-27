
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        actor_names,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        ranked_movies
    WHERE 
        actor_count > 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.actor_names,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords
FROM 
    top_movies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.title, tm.production_year, tm.actor_count, tm.actor_names
ORDER BY 
    tm.actor_count DESC;
