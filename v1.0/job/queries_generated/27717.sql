WITH ranked_titles AS (
    SELECT 
        t.title AS movie_title,
        at.production_year,
        COUNT(DISTINCT CASE WHEN ci.person_role_id = rt.id THEN ci.person_id END) AS role_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        title t ON at.title = t.title
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        at.production_year, t.title
),
top_movies AS (
    SELECT
        movie_title,
        production_year,
        role_count
    FROM 
        ranked_titles
    WHERE 
        rank <= 5
),
movie_keywords AS (
    SELECT 
        tm.movie_title,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        top_movies tm
    JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM title WHERE title = tm.movie_title AND production_year = tm.production_year LIMIT 1)
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.movie_title
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.role_count,
    COALESCE(mk.keywords, '{}') AS keywords
FROM 
    top_movies tm
LEFT JOIN 
    movie_keywords mk ON tm.movie_title = mk.movie_title
ORDER BY 
    tm.production_year DESC, 
    tm.role_count DESC;

This SQL query performs several complex operations:

1. **ranked_titles** CTE: This collects the titles of movies grouped by production year and counts distinct roles to find how many unique persons played roles in each movie for a specific year. It assigns a rank to movies based on the number of roles associated with them.

2. **top_movies** CTE: This filters the ranked titles to only keep the top 5 movies per production year based on the role count.

3. **movie_keywords** CTE: This aggregates the keywords associated with the top movies determined in the previous step by joining the necessary tables.

4. The final SELECT statement fetches the relevant top movie information and left-joins it with the keywords, displaying a list of top movies along with their production year, role count, and associated keywords, sorted by year and role count.
