WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ai.person_id AS actor_id,
        a.name AS actor_name,
        1 AS level
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    WHERE 
        a.name IS NOT NULL
    UNION ALL
    SELECT 
        ai.person_id,
        a.name,
        ah.level + 1
    FROM 
        actor_hierarchy ah
    JOIN 
        cast_info ci ON ah.actor_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
)
, movie_details AS (
    SELECT 
        mt.movie_id,
        mt.title AS movie_title,
        mt.production_year,
        STRING_AGG(ka.name, ', ') AS cast_names,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_casts
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.movie_id, mt.title, mt.production_year
)
SELECT 
    md.movie_title,
    COALESCE(md.production_year, 'Unknown Year') AS year,
    md.cast_names,
    md.cast_count,
    NULLIF(md.noted_casts, 0) AS active_cast,
    ah.actor_name,
    ah.level,
    ROW_NUMBER() OVER (PARTITION BY md.movie_id ORDER BY ah.level DESC) AS rank_level
FROM 
    movie_details md
LEFT JOIN 
    actor_hierarchy ah ON md.cast_count > 0
WHERE 
    EXISTS (
        SELECT 1 
        FROM movie_keyword mk 
        WHERE mk.movie_id = md.movie_id AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%Action%')
    )
ORDER BY 
    md.production_year DESC,
    md.cast_count DESC
LIMIT 
    10;

### Explanation of the Query:

1. **Recursive CTE**: The `actor_hierarchy` CTE builds a hierarchy of actors that have appeared in movies. Each actor's level is tracked to reflect their depth in the hierarchy.

2. **Movie Details CTE**: The `movie_details` CTE aggregates information about movies, including the title, production year, list of cast members, count of distinct cast members, and a count of noted casts (those with a non-null note).

3. **Main Query**: The main query selects movie titles and their details from the `movie_details` table. It combines this with information from the `actor_hierarchy` to list cast members along with their hierarchy level.

4. **COALESCE**: Used to provide a fallback string for production years that are NULL.

5. **NULLIF**: Converts the count of active casts to NULL if it is zero, effectively filtering out non-active casts in a way that can be visually distinct.

6. **Subquery with EXISTS**: Filters movies by checking if they have been tagged with a specific keyword (in this case, 'Action') using a subquery.

7. **ROW_NUMBER() Window Function**: Assigns a ranking to the actors based on their level within a movie, giving precedence to deeper (higher level) actors.

8. **Sorting and Limiting**: Finally, it sorts the results by production year and cast count, limiting the output to the top 10 entries.

This query effectively combines multiple SQL concepts into a coherent structure for performance benchmarking across different dimensions of the dataset.
