-- This query benchmarks string processing by retrieving detailed movie and 
-- actor information based on various string manipulations and joins.

WITH ActorMovies AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        t.title AS movie_title, 
        t.production_year AS year,
        kc.keyword AS keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        a.name ILIKE '%Smith%' -- Looking for actors with 'Smith' in their name
)

SELECT 
    am.actor_id,
    am.actor_name,
    STRING_AGG(am.movie_title || ' (' || am.year || ')', ', ' ORDER BY am.year DESC) AS movies,
    STRING_AGG(DISTINCT am.keyword, ', ') AS keywords,
    COUNT(*) AS movie_count
FROM 
    ActorMovies am
WHERE 
    am.movie_rank <= 3  -- Limit to the top 3 movies per actor
GROUP BY 
    am.actor_id, 
    am.actor_name
ORDER BY 
    COUNT(*) DESC; -- Order by the number of movies in descending order

This SQL query selects actors with 'Smith' in their name, retrieves their movie titles, production years, and associated keywords, while applying string manipulation functions for aggregation and formatting. It also limits results to the top three movies for each actor and orders the final output by movie count.
