WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mt.kind, 'Unknown') AS movie_type,
        COALESCE(m.production_year, 'N/A') AS production_year,
        0 AS depth
    FROM 
        aka_title mt
    JOIN 
        title m ON mt.id = m.id
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        linked_movie.linked_movie_id AS movie_id,
        linked_movie.title,
        COALESCE(mt.kind, 'Unknown') AS movie_type,
        COALESCE(m.production_year, 'N/A') AS production_year,
        mh.depth + 1
    FROM 
        movie_link linked_movie
    JOIN 
        title m ON linked_movie.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON linked_movie.movie_id = mh.movie_id
)

SELECT 
    mh.title,
    mh.movie_type,
    mh.production_year,
    array_agg(DISTINCT ak.name) AS actor_names,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(CASE 
            WHEN mt.production_year BETWEEN 2000 AND 2023 
            THEN 1 
            ELSE 0 
        END) AS recent_movie_count,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_type ORDER BY COUNT(DISTINCT ak.name) DESC) AS actor_rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    aka_title mt ON mh.movie_id = mt.movie_id
WHERE 
    mh.depth < 3
GROUP BY 
    mh.movie_id, mh.title, mh.movie_type, mh.production_year
HAVING 
    COUNT(DISTINCT ak.name) > 0
ORDER BY 
    actor_rank ASC, 
    mh.production_year DESC 
LIMIT 100 OFFSET 10;

### Explanation:
1. **CTE (Common Table Expression)**: The query starts with a recursive CTE called `movie_hierarchy` that builds a hierarchy of movies based on links between them. It selects information from `aka_title` and `title`, and continues to find linked movies.

2. **Join Operations**: The main SELECT statement incorporates outer joins to gather actor names (from `aka_name`) and associated movie companies (from `movie_companies`), ensuring that all movie details are preserved.

3. **Aggregation Functions**: It uses `array_agg` to collect distinct actor names into an array and counts the distinct companies.

4. **Window Functions**: `ROW_NUMBER()` is used here to rank the movies by the number of actors in each movie type.

5. **Complicated Conditions/Predicates**: The WHERE clause limits the depth of the movie hierarchy and ensures that only movies with actors are counted. The HAVING clause filters out any entries with no actors contributing.

6. **Unusual Edge Cases**: The query handles NULL logic with COALESCE to provide default values for movie type and production year, ensuring the output remains informative even when there is missing data.

7. **Ordering and Pagination**: Finally, results are ordered by actor rank and production year, with a pagination mechanism in place to return specific sets of rows.

This multi-faceted approach demonstrates complex SQL constructs while also focusing on obtaining meaningful data from the defined schema for performance benchmarking.
