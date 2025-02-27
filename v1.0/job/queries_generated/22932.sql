WITH movie_actors AS (
    SELECT 
        c.movie_id,
        a.person_id,
        a.name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),
aging_movies AS (
    SELECT 
        t.title,
        t.production_year,
        EXTRACT(YEAR FROM CURRENT_DATE) - t.production_year AS movie_age,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        EXTRACT(YEAR FROM CURRENT_DATE) - t.production_year >= 10
),
highlighted_movies AS (
    SELECT 
        m.title,
        m.production_year,
        m.movie_age,
        a.person_id,
        a.name AS actor_name
    FROM 
        aging_movies m
    JOIN 
        movie_actors a ON m.movie_id = a.movie_id
    WHERE 
        m.keyword_count > 1
)
SELECT 
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    m.movie_age AS Age_of_Movie,
    STRING_AGG(a.actor_name, ', ') AS Actors_List
FROM 
    highlighted_movies m
LEFT JOIN 
    movie_actors a ON m.movie_id = a.movie_id
WHERE 
    (m.movie_age IS NOT NULL OR m.movie_age >= 10)
    AND (a.actor_name IS NOT NULL OR m.actor_id IS NULL)
GROUP BY 
    m.title, m.production_year, m.movie_age
ORDER BY 
    m.movie_age DESC, m.title
LIMIT 50;
