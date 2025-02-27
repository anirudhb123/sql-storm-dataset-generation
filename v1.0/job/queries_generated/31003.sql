WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ci.person_id AS actor_id,
        ci.movie_id,
        1 AS generation
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name LIKE 'A%'  -- Starting from actors whose names begin with 'A'

    UNION ALL

    SELECT 
        ci.person_id,
        ci.movie_id,
        ah.generation + 1
    FROM 
        actor_hierarchy ah
    JOIN 
        cast_info ci ON ci.movie_id = ah.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name NOT LIKE 'A%'  -- Exclude names starting with 'A' to avoid circular references
),

-- Getting the total number of movies each actor has appeared in.
actor_movie_count AS (
    SELECT 
        actor_id,
        COUNT(DISTINCT movie_id) AS movie_count
    FROM 
        actor_hierarchy
    GROUP BY 
        actor_id
),

-- Join to get additional details from the person_info table
actor_details AS (
    SELECT 
        ak.name AS actor_name,
        amc.movie_count,
        pi.info AS additional_info
    FROM 
        actor_movie_count amc
    JOIN 
        aka_name ak ON amc.actor_id = ak.person_id
    LEFT JOIN 
        person_info pi ON amc.actor_id = pi.person_id
)

-- Final selection of actor details and their movie counts
SELECT 
    ad.actor_name,
    COALESCE(ad.movie_count, 0) AS total_movies,
    ad.additional_info,
    ROW_NUMBER() OVER (ORDER BY ad.movie_count DESC) AS rank
FROM 
    actor_details ad
WHERE 
    ad.movie_count IS NOT NULL
ORDER BY 
    total_movies DESC
LIMIT 10;

This query does the following:

1. Uses a recursive Common Table Expression (CTE) `actor_hierarchy` to build a hierarchy of actors starting with those whose names begin with 'A'. It continues to include collaborative actors from the same movie, ignoring those whose names also start with 'A'.
2. The `actor_movie_count` CTE computes how many distinct movies each actor has appeared in.
3. The `actor_details` CTE joins the count with the `aka_name` and `person_info` tables to retrieve the complete actor name and additional info about the actor.
4. Finally, the main SELECT statement fetches and ranks the top actors by movie count, defaulting the count to zero using `COALESCE` if no movies are found, and limits the results to the top 10 actors.
