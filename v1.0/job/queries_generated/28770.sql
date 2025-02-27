WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ARRAY_AGG(DISTINCT a.name) AS actor_names,
        ROW_NUMBER() OVER (ORDER BY COUNT(c.id) DESC) AS rank
    FROM title t
    JOIN cast_info c ON t.id = c.movie_id
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY t.id, t.title, t.production_year
),
actor_statistics AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(c.movie_id) AS movies_appeared_in,
        ARRAY_AGG(DISTINCT t.title) AS movies_titles
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN title t ON c.movie_id = t.id
    GROUP BY a.id, a.name
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.actor_names,
    as.movies_appeared_in,
    as.movies_titles
FROM 
    ranked_movies rm
JOIN 
    actor_statistics as ON as.movies_titles && rm.actor_names
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.cast_count DESC;
