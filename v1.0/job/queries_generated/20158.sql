WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
actor_roles AS (
    SELECT 
        ak.name AS actor_name,
        mt.title AS movie_title,
        rt.role,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title mt ON ci.movie_id = mt.id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ak.name, mt.title, rt.role
),
movies_with_keywords AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mt.id, mt.title
),
highlights AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mw.keywords, 'No Keywords') AS keywords,
        COUNT(ar.movie_count) AS role_count,
        MAX(ar.actor_name) OVER (PARTITION BY rm.movie_id) AS lead_actor
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movies_with_keywords mw ON rm.movie_id = mw.movie_id
    LEFT JOIN 
        actor_roles ar ON rm.title = ar.movie_title
    WHERE 
        rm.year_rank = 1
)

SELECT 
    h.title,
    h.production_year,
    h.keywords,
    h.role_count,
    h.lead_actor
FROM 
    highlights h
WHERE 
    h.production_year IS NOT NULL
ORDER BY 
    h.production_year DESC, 
    h.role_count DESC
LIMIT 10;

### Explanation:
1. **CTEs**: Three Common Table Expressions (CTEs) are used:
   - `ranked_movies` computes the number of casts per movie and ranks them by year.
   - `actor_roles` aggregates actors' roles alongside the count of movies they've appeared in.
   - `movies_with_keywords` concatenates keywords associated with each movie.

2. **LEFT JOINs**: Used to ensure that we capture movies with no keywords or roles.

3. **STRING_AGG**: Combines multiple keywords into a single string.

4. **COALESCE**: Provides a default string for movies without keywords.

5. **Window Function (`MAX`)**: Gets the name of the lead actor per movie.

6. **Complex WHERE Clause**: Filters for the first-ranked movie of each year with a non-NULL production year.

7. **ORDER BY and LIMIT**: Sorts the results by the most recent year and highest number of roles, limiting to the top 10 results.

This query encapsulates various SQL functionalities and showcases complex relationships and aggregations among the data available in the schema.
