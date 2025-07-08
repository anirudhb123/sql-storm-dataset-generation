
WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year > 2000
),
actor_counts AS (
    SELECT 
        r.actor_name,
        COUNT(*) AS movie_count
    FROM 
        ranked_movies r
    GROUP BY 
        r.actor_name
),
top_actors AS (
    SELECT 
        actor_name,
        movie_count,
        RANK() OVER (ORDER BY movie_count DESC) AS actor_rank
    FROM 
        actor_counts
)
SELECT 
    ta.actor_name,
    ta.movie_count,
    LISTAGG(rm.title, ', ') WITHIN GROUP (ORDER BY rm.title) AS movies
FROM 
    top_actors ta
JOIN 
    ranked_movies rm ON ta.actor_name = rm.actor_name
WHERE 
    ta.actor_rank <= 10
GROUP BY 
    ta.actor_name, ta.movie_count
ORDER BY 
    ta.movie_count DESC;
