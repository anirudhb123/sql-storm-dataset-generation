WITH movie_actors AS (
    SELECT 
        ak.name AS actor_name,
        mk.title AS movie_title,
        mk.production_year,
        rt.role AS actor_role
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title mk ON ci.movie_id = mk.movie_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ak.name IS NOT NULL
), 
movie_keywords AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
), 
full_movie_info AS (
    SELECT 
        ma.actor_name,
        ma.movie_title,
        ma.production_year,
        ma.actor_role,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
    FROM 
        movie_actors ma
    LEFT JOIN 
        movie_keywords mk ON ma.movie_title = mk.movie_id
    GROUP BY 
        ma.actor_name, ma.movie_title, ma.production_year, ma.actor_role
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    actor_role,
    keywords
FROM 
    full_movie_info
WHERE 
    keywords LIKE '%action%' OR 
    keywords LIKE '%drama%'
ORDER BY 
    production_year DESC,
    actor_name ASC;

This query benchmarks string processing through the following steps:

1. **CTE "movie_actors":** Fetches the names of actors, their roles, and the movies they have acted in, joining the tables `aka_name`, `cast_info`, `aka_title`, and `role_type`.

2. **CTE "movie_keywords":** Retrieves the keywords associated with movies by joining `movie_keyword` and `keyword`.

3. **Aggregate Movie Info:** Combines actors' information with their movies and associated keywords, utilizing `STRING_AGG` to collate keywords into a single string for each movie.

4. **Final Selection:** Filters for movies that have "action" or "drama" in their keywords and orders the results by production year and actor name.

This SQL structure effectively combines multiple string operations and aggregation techniques to produce a comprehensive list of actors and their movies based on specific keyword criteria.
