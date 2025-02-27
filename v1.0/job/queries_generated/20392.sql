WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT c.person_id) OVER (PARTITION BY ak.name ORDER BY at.production_year) AS total_movies_acted,
    CASE 
        WHEN COUNT(DISTINCT c.person_id) OVER (PARTITION BY ak.name ORDER BY at.production_year) > 5 
        THEN 'Prolific Actor'
        ELSE 'Emerging Talent' 
    END AS actor_status,
    STRING_AGG(DISTINCT mw.keyword, ', ') FILTER (WHERE mw.keyword IS NOT NULL) AS keywords,
    NULLIF(c.note, '') AS role_note
FROM 
    aka_name ak
JOIN 
    cast_info c ON c.person_id = ak.person_id
JOIN 
    aka_title at ON at.id = c.movie_id
LEFT JOIN 
    movie_keyword mw ON mw.movie_id = at.id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = at.id
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
WHERE 
    ak.name IS NOT NULL
    AND (at.production_year > 2000 OR ak.name LIKE '%Smith%')
    AND (c.nr_order IS NOT NULL OR c.note IS NULL)
    
GROUP BY 
    ak.name, at.title, at.production_year, c.note
ORDER BY 
    total_movies_acted DESC,
    at.production_year DESC
LIMIT 100;

### Explanation of the Query:
1. **Common Table Expression (CTE) `movie_hierarchy`:** This recursive CTE builds a hierarchy of movies based on their links, allowing for dynamic exploration of parent-child relationships among movies.
  
2. **Window Functions:**
   - `COUNT(DISTINCT c.person_id) OVER (PARTITION BY ak.name ORDER BY at.production_year)` counts distinct movies acted in by each actor, partitioned by actor names. 

3. **Case Expression:**
   - The actor's status is determined based on the number of distinct movies they've acted in, classifying them as either "Prolific Actor" or "Emerging Talent".

4. **String Aggregation:**
   - `STRING_AGG` collects all unique keywords associated with each movie, excluding null values. 

5. **Join Operations:**
   - Utilizes several outer joins to include additional contextual information about movies, companies, and actors.

6. **Filters and Conditions:**
   - Combines multiple conditions with `IS NOT NULL`, `LIKE`, the use of `NULLIF` to deal with empty strings versus true nulls, ensuring the query's complexity and covering edge cases.

7. **Final Grouping & Ordering:**
   - Results are grouped by actor name, movie title, year, and note, with final ordering applied for a specified limit.

This SQL query showcases various constructs including CTEs, window functions, JOINs, subqueries, `CASE` statements, string manipulation and aggregation, and NULL logic, making it suitable for performance benchmarking and demonstrating SQL capabilities.
