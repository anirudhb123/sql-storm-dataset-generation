
WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_actor_count
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, a.name, k.keyword
),

top_movies AS (
    SELECT 
        title, 
        production_year, 
        actor_name,
        keyword,
        actor_count,
        rank_by_actor_count
    FROM 
        ranked_movies
    WHERE 
        rank_by_actor_count <= 5
)

SELECT 
    production_year, 
    LISTAGG(title || ' (' || actor_name || ' - ' || keyword || ')', ', ') AS movie_details
FROM 
    top_movies
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
