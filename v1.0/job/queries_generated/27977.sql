WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        COUNT(ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS co_stars
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
top_movies AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_name,
    tm.actor_count,
    tm.co_stars
FROM 
    top_movies tm
WHERE 
    tm.rank <= 3
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;

This SQL query takes the following approach:

1. **Ranked Movies**: It first creates a common table expression (CTE) called `ranked_movies`, which retrieves movie titles along with their production years and a count of actors associated with each movie. It also concatenates the co-stars' names into a single string.

2. **Top Movies**: A second CTE `top_movies` ranks these movies by the number of actors for each year.

3. **Final Selection**: The final selection retrieves the top three movies per year based on their actor count and orders the results by recent production years and the number of actors.

This query showcases string processing through the use of `STRING_AGG()` for concatenating actor names and utilizes ranking to benchmark movie data across different criteria.
