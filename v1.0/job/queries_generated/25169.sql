WITH ranked_movies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
top_movies AS (
    SELECT 
        movie_title, 
        production_year
    FROM 
        ranked_movies
    WHERE 
        actor_rank <= 5
),
movie_keywords AS (
    SELECT 
        t.title,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM 
        top_movies tm
    JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        title t ON tm.movie_id = t.id
    GROUP BY 
        t.title
)
SELECT 
    tm.production_year,
    tk.movie_title,
    tk.keywords
FROM 
    top_movies tm
JOIN 
    movie_keywords tk ON tm.movie_title = tk.movie_title
ORDER BY 
    tm.production_year DESC, tk.movie_title;

This query performs a series of operations:

1. The `ranked_movies` CTE ranks movies based on the number of unique actors for each production year.
2. The `top_movies` CTE filters the top 5 movies for each production year.
3. The `movie_keywords` CTE aggregates keywords for the top movies.
4. The final SELECT statement retrieves the production year, movie titles, and their associated keywords, ordered by production year descending and movie title. 

Ensure you adjust the column names and joins as per the actual data structure used in your database.
