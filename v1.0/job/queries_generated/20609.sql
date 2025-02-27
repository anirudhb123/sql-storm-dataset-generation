WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.linked_movie_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    STRING_AGG(DISTINCT mt.title, ', ') FILTER (WHERE mt.production_year IS NOT NULL) AS movie_titles,
    AVG(mt.production_year) AS avg_production_year,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id IN (SELECT movie_id FROM movie_hierarchy WHERE level > 1)) AS total_keywords_related_movies,
    COALESCE((SELECT COUNT(*) FROM company_name cn WHERE cn.country_code = 'US' AND cn.name LIKE '%Studios%'), 0) AS studio_count,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY COUNT(DISTINCT mc.movie_id) DESC) AS actor_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = cc.movie_id
LEFT JOIN 
    aka_title mt ON mc.movie_id = mt.id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
    AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
    AND ci.nr_order = 1  -- Only considering the lead role
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mc.movie_id) >= 5
ORDER BY 
    total_movies DESC, 
    actor_name ASC;

### Explanation:

1. **Common Table Expression (CTE)**: A recursive CTE named `movie_hierarchy` is used to retrieve movies and any linked movies, maintaining a hierarchy of links with levels.

2. **String Aggregation and NULL Handling**: The `STRING_AGG` function is used to collect movie titles along with a `FILTER` to exclude NULL production years. `COALESCE` is deployed to handle cases where there may be no U.S. studios.

3. **Window Functions**: `ROW_NUMBER` is used to rank actors based on their total movie appearances.

4. **Subquery Logic**: A subquery counts distinct keywords for movies from a hierarchical SQL context (movies that have linked movies), showcasing more obscure SQL execution pathways.

5. **Complicated Predicate and Expressions**: The query incorporates various predicates, including checks for non-NULL actor names, excluding empty strings, and filtering on certain `kind_id` values.

6. **Aggregation and Filtering**: The results are grouped by actor names that appear in at least 5 movies, showcasing aggregate functions and filtering simultaneously.

7. **JOINs**: A combination of INNER and LEFT JOINs pulls in necessary data across various tables, ensuring comprehensive results while allowing for NULLs in certain relationships. 

This SQL query is designed to implement various complex mechanisms and handle potential edge cases while maximizing performance through optimal conditions.
