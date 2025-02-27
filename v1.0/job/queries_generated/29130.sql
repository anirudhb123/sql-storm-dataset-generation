WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ka.person_id) AS actor_count,
        STRING_AGG(DISTINCT ka.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ka ON c.person_id = ka.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
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
        keywords,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC, production_year DESC) AS ranking
    FROM 
        ranked_movies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.actor_names,
    tm.keywords
FROM 
    top_movies tm
WHERE 
    tm.ranking <= 10;
