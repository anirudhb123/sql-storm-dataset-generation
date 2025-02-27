
WITH ranked_titles AS (
    SELECT 
        a.title AS title,
        t.production_year AS year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title a 
    JOIN 
        title t ON a.movie_id = t.id
    JOIN 
        cast_info c ON a.movie_id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        a.title, t.production_year
),

top_movies AS (
    SELECT 
        title, 
        year,
        cast_count,
        actor_names,
        year_rank
    FROM 
        ranked_titles
    WHERE 
        year_rank <= 5  
)

SELECT 
    tm.title, 
    tm.year, 
    tm.cast_count, 
    tm.actor_names,
    k.keyword AS movie_keyword
FROM 
    top_movies tm
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT a.movie_id FROM aka_title a WHERE a.title = tm.title LIMIT 1) 
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
ORDER BY 
    tm.year DESC, 
    tm.cast_count DESC;
