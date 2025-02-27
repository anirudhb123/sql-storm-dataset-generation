WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        t.title,
        1 AS level
    FROM
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    WHERE 
        mc.company_type_id IN (
            SELECT id FROM company_type WHERE kind = 'Production'
        )
    
    UNION ALL

    SELECT
        m.movie_id,
        t.title,
        mh.level + 1
    FROM
        movie_hierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title t ON ml.linked_movie_id = t.id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    STRING_AGG(DISTINCT t.title, ', ') AS titles,
    COALESCE(NULLIF(SUM(mh.level), 0), 'Not Applicable') AS hierarchy_level,
    AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_roles
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = c.movie_id
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    movie_count DESC;

### Explanation of the Query:
1. **Common Table Expression (CTE):** A recursive CTE `movie_hierarchy` is defined to build a hierarchy of movies based on linked movies.
  
2. **Initial Selection in CTE:**
   - It selects movies produced by companies that have a type of 'Production' and establishes a base level for them.

3. **Recursive Part of CTE:**
   - It then joins the base level with `movie_link` to find linked movies, incrementing the level for each subsequent link.

4. **Main Query:**
   - Selects actors' names and counts how many distinct movies they were cast in.
   - Collects all titles of their movies into a single string using `STRING_AGG`.
   - Uses `COALESCE` and `NULLIF` to handle the hierarchy level, ensuring it returns 'Not Applicable' if there are no levels.
   - Computes the average of noted roles with a simple CASE statement to define the condition for noting roles.

5. **Filtering with HAVING Clause:**
   - Filters to only include actors who appeared in more than 5 distinct movies.

6. **Ordering:**
   - The results are ordered by the number of movies in descending order. 

This query combines various SQL constructs to create a complex but meaningful report about actors and their movie contributions, showcasing the capabilities of SQL for performance benchmarking and data analysis across multiple relationships.
