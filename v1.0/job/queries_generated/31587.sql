WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title AS movie_title,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM 
        aka_title et
    JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
),

cast_movies AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ci.role_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),

movie_ratings AS (
    SELECT 
        movie_id,
        AVG(CAST(info AS FLOAT)) AS average_rating
    FROM 
        movie_info
    WHERE 
        info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        movie_id
),

selected_movies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        COALESCE(mr.average_rating, 0) AS average_rating
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_ratings mr ON mh.movie_id = mr.movie_id
    WHERE 
        mh.level = 1
)

SELECT 
    sm.movie_title,
    sm.average_rating,
    STRING_AGG(cm.actor_name, ', ') AS actors,
    CASE 
        WHEN sm.average_rating >= 8 THEN 'Excellent'
        WHEN sm.average_rating BETWEEN 5 AND 7 THEN 'Average'
        ELSE 'Poor'
    END AS rating_category
FROM 
    selected_movies sm
LEFT JOIN 
    cast_movies cm ON sm.movie_id = cm.movie_id
GROUP BY 
    sm.movie_id, sm.movie_title, sm.average_rating
ORDER BY 
    sm.average_rating DESC;

### Explanation:
1. **RECURSIVE CTE (`movie_hierarchy`)**: This part builds the movie hierarchy, retrieving movies and their episodes.
2. **Second CTE (`cast_movies`)**: This combines movies with their actors, numbering them by their names for a structured output.
3. **Third CTE (`movie_ratings`)**: This aggregates movie ratings to find the average rating for each movie.
4. **Final Selection**: This combines everything, joining selected movies with their cast and using string aggregation to list actors. It categorizes movies based on ratings into 'Excellent', 'Average', or 'Poor'. 
5. **Complex Predicates**: Various JOINs and COALESCE functions handle NULL values gracefully, ensuring robust data output.

Overall, this query is designed to retrieve a ranked list of movies alongside their average ratings and primary actors in a clear and structured manner, providing rich insights into the data.
