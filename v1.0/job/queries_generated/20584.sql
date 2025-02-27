WITH movie_years AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.production_year DESC) AS year_rank
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
actor_role_counts AS (
    SELECT 
        cast_info.person_id,
        aka_name.name,
        COUNT(DISTINCT cast_info.movie_id) AS role_count
    FROM 
        cast_info
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY 
        cast_info.person_id, aka_name.name
),
top_actors AS (
    SELECT 
        person_id,
        name,
        role_count,
        RANK() OVER (ORDER BY role_count DESC) AS actor_rank
    FROM 
        actor_role_counts
    WHERE 
        role_count > 5
),
complex_movies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        m.movie_id, m.title, m.production_year
    HAVING 
        COUNT(DISTINCT mc.company_id) > 1 AND MAX(m.production_year) >= 2000
)
SELECT 
    movies.title,
    movies.production_year,
    actors.name AS top_actor,
    actors.role_count,
    COALESCE(COMPLEX.company_count, 0) AS complex_company_count,
    COMPLEX.company_names
FROM 
    complex_movies AS COMPLEX
JOIN 
    movie_years AS movies ON COMPLEX.movie_id = movies.movie_id
LEFT JOIN 
    top_actors AS actors ON actors.actor_rank <= 3
WHERE 
    movies.year_rank <= 5 OR actors.role_count > 10
ORDER BY 
    movies.production_year DESC, actors.role_count DESC
LIMIT 10;

This query includes:
- Common Table Expressions (CTEs) to organize the logic neatly: `movie_years`, `actor_role_counts`, `top_actors`, and `complex_movies`.
- Outer joins to ensure inclusion of all movies, even those without associated companies.
- A mixed use of window functions (for ranking) and aggregated string functions (to get company names).
- Complex filtering criteria through HAVING and WHERE clauses to handle edge cases, like ensuring the movies are from a specific period and counting roles.
- Handling NULLs with `COALESCE` to manage cases where a movie might not have a complex association.
- Limits the result to the top actors and recent movies.
