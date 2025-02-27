WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        ca.nr_order,
        1 AS depth
    FROM 
        cast_info ca
    INNER JOIN aka_name an ON ca.person_id = an.person_id
    WHERE 
        an.name IS NOT NULL AND an.name <> ''
    
    UNION ALL
    
    SELECT 
        ca.person_id,
        ca.movie_id,
        ca.nr_order,
        ah.depth + 1
    FROM 
        actor_hierarchy ah
    JOIN cast_info ca ON ah.movie_id = ca.movie_id
    WHERE 
        ca.person_id <> ah.person_id
)

SELECT 
    DISTINCT a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT ah.movie_id) OVER (PARTITION BY a.person_id) AS movie_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COALESCE(ct.kind, 'Unknown') AS company_type,
    CASE 
        WHEN COUNT(DISTINCT ah.movie_id) > 5 THEN 'Prolific Actor'
        ELSE 'Emerging Actor'
    END AS actor_status
FROM 
    aka_name a 
LEFT JOIN cast_info c ON a.person_id = c.person_id 
LEFT JOIN aka_title t ON c.movie_id = t.movie_id 
LEFT JOIN movie_companies mc ON t.id = mc.movie_id 
LEFT JOIN company_type ct ON mc.company_type_id = ct.id 
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id 
LEFT JOIN keyword kw ON mk.keyword_id = kw.id 
LEFT JOIN actor_hierarchy ah ON c.movie_id = ah.movie_id
WHERE 
    a.name IS NOT NULL 
    AND (t.production_year >= 2000 OR t.production_year IS NULL) 
    AND (ct.kind != 'Independent' OR ct.kind IS NULL)
GROUP BY 
    a.person_id, t.id, ct.kind
HAVING 
    COUNT(DISTINCT ah.movie_id) > 2
ORDER BY 
    movie_count DESC, actor_name ASC;

### Explanation of Constructs Used:
1. **Common Table Expressions (CTE)**: The `actor_hierarchy` CTE is a recursive query that builds a hierarchical structure of actors based on their movie roles, allowing us to explore dependencies in roles across different movies.

2. **Window Functions**: The query aggregates data using a window function to count how many movies each actor has participated in, partitioned by actor.

3. **Outer Joins**: The `LEFT JOIN` statements ensure that we still include actors who may not have associated movie titles, keywords, or company types.

4. **Aggregate Functions**: The `COUNT` and `STRING_AGG` functions are used to get the number of movies and concatenate keywords, respectively.

5. **Complex Predicates**: The `WHERE` clause contains multiple conditions, including handling NULL values and using `COALESCE` to determine company types.

6. **Case Statements**: The `CASE` statement categorizes actors based on the number of movies they've appeared in, creating a meaningful label for each.

7. **Group and Having Clauses**: The `GROUP BY` clause aggregates results based on actor and movie relations, while the `HAVING` clause filters for actors involved in more than two movies.

This SQL query uses various advanced constructs and corner cases, making it complex yet informative for performance benchmarking within the provided database schema.
