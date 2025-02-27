WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        mh.level < 3  -- Limit recursion to three levels
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    count(ci.id) OVER (PARTITION BY ci.movie_id) AS cast_count,
    CASE 
        WHEN m.production_year < 2010 THEN 'Classic'
        ELSE 'Modern'
    END AS movie_age_category,
    COALESCE(k.keyword, 'No Keyword') AS keyword_used,
    empty_comp.name AS empty_company_name
FROM 
    movie_hierarchy m
JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name empty_comp ON mc.company_id = empty_comp.id AND empty_comp.name IS NULL
WHERE 
    a.name IS NOT NULL
    AND m.title ILIKE '%adventure%'
ORDER BY 
    m.production_year DESC, CAST_COUNT DESC;


### Breakdown of the Query

1. **Common Table Expression (CTE)**: 
   - `movie_hierarchy`: a recursive CTE that builds a hierarchy of movies linked to other movies, limiting the depth of recursion to three levels. It starts with movies produced from 2000 onward.

2. **SELECT Statement**:
   - Selects various columns: actor name, movie title, production year, a computed count of cast members for each movie (using a window function), an age category for the movie, and keywords associated with the movies.
   - It makes use of the `CASE` and `COALESCE` functions for conditional and null logic.

3. **Joins**:
   - It combines multiple tables using inner joins and left joins to gather all necessary information, including actors and keywords.
   - Additionally, it attempts to fetch company names where a company was linked to a movie, allowing for NULL values to default into `empty_company_name`.

4. **Filtering Conditions**:
   - Only includes actors (with non-null names) and movies with titles that contain the keyword 'adventure'.

5. **Ordering**:
   - Results are sorted first by the production year, then by the cast count in a descending manner.

This query is designed to provide insights into movie actors from a recently defined hierarchy of linked movies, alongside performance metrics that could be useful for benchmarking query execution times due to its complexity and scale.
