WITH ranked_movies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rnk
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
active_actors AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.person_id, ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
top_movies AS (
    SELECT 
        m.title, 
        m.production_year, 
        m.cast_count
    FROM 
        ranked_movies m
    WHERE 
        m.rnk <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(a.name, 'Unknown Actor') AS actor_name,
    a.movie_count,
    CASE 
        WHEN a.movie_count IS NULL THEN 'No movies available'
        ELSE 'Movies available'
    END AS availability_status
FROM 
    top_movies tm
LEFT JOIN 
    active_actors a ON a.movie_count > 0
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC
LIMIT 20;
