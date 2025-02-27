WITH ranked_movies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
filtered_movies AS (
    SELECT 
        actor_id,
        actor_name,
        title_id,
        movie_title,
        production_year
    FROM 
        ranked_movies
    WHERE 
        year_rank <= 3
),
movie_keywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
movie_details AS (
    SELECT 
        f.actor_id,
        f.actor_name,
        f.movie_title,
        f.production_year,
        COALESCE(k.keywords, 'No Keywords') AS keywords
    FROM 
        filtered_movies f
    LEFT JOIN 
        movie_keywords k ON f.title_id = k.movie_id
)
SELECT 
    d.actor_name,
    COUNT(d.movie_title) AS movie_count,
    AVG(d.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT d.keywords, '; ') AS all_keywords
FROM 
    movie_details d
GROUP BY 
    d.actor_name
HAVING 
    COUNT(d.movie_title) > 1
ORDER BY 
    movie_count DESC, avg_production_year;
