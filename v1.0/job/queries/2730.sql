WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rn
    FROM 
        aka_title a
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
actor_movies AS (
    SELECT 
        c.person_id,
        t.title,
        t.production_year,
        COUNT(c.movie_id) OVER (PARTITION BY c.person_id ORDER BY t.production_year) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_title t ON c.movie_id = t.id
),
max_movies AS (
    SELECT 
        person_id,
        MAX(movie_count) AS max_movies_count
    FROM 
        actor_movies
    GROUP BY 
        person_id
)
SELECT 
    a.name AS actor_name,
    r.title,
    r.production_year,
    COALESCE(m.max_movies_count, 0) AS max_movie_count
FROM 
    aka_name a
JOIN 
    actor_movies am ON a.person_id = am.person_id
JOIN 
    ranked_movies r ON am.title = r.title AND am.production_year = r.production_year
LEFT JOIN 
    max_movies m ON am.person_id = m.person_id
WHERE 
    r.rn <= 5 AND
    (m.max_movies_count > 5 OR m.max_movies_count IS NULL)
ORDER BY 
    a.name,
    r.production_year DESC;
