WITH actor_movie_count AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
),
movies_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
),
actor_movie_keywords AS (
    SELECT 
        am.actor_name,
        mwk.movie_title,
        mwk.keywords
    FROM 
        actor_movie_count am
    JOIN 
        cast_info ci ON am.actor_name = (
            SELECT ak.name 
            FROM aka_name ak 
            WHERE ak.person_id = ci.person_id
        )
    JOIN 
        movies_with_keywords mwk ON ci.movie_id = mwk.movie_id
)
SELECT 
    actor_name,
    movie_title,
    keywords,
    (SELECT COUNT(*) FROM actor_movie_count) AS total_actors
FROM 
    actor_movie_keywords
WHERE 
    movie_title ILIKE '%action%'  -- Filtering for action movies
ORDER BY 
    movie_title ASC;

This SQL query performs the following tasks:

1. **actor_movie_count CTE**: Counts the number of movies each actor has appeared in.
2. **movies_with_keywords CTE**: Aggregates movie titles with their associated keywords.
3. **actor_movie_keywords CTE**: Joins the previous results to create a dataset containing actor names, movie titles, and their keywords.
4. The final `SELECT` retrieves actor names, movie titles, and their keywords but only for movies that include the word "action" in their title, sorted alphabetically, along with a total count of distinct actors for context.
