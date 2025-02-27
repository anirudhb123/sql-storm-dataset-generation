WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    a.name AS actor_name,
    mt.title AS movie_title,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(CASE WHEN pb.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') THEN pb.info END) AS budget_info_count,
    CASE 
        WHEN AVG(mh.level) IS NOT NULL THEN ROUND(AVG(mh.level), 2) 
        ELSE 0 
    END AS avg_link_level
FROM 
    cast_info c
JOIN 
    aka_name a ON a.person_id = c.person_id
JOIN 
    movie_companies mc ON mc.movie_id = c.movie_id
JOIN 
    aka_title mt ON mt.id = c.movie_id
LEFT JOIN 
    movie_keyword mw ON mw.movie_id = mt.id
LEFT JOIN 
    keyword kw ON kw.id = mw.keyword_id
LEFT JOIN 
    movie_info pb ON pb.movie_id = mt.id
JOIN 
    movie_hierarchy mh ON mh.movie_id = mt.id
GROUP BY 
    a.name, mt.title
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    avg_link_level DESC, actor_name;

### Explanation:

1. **CTE (Common Table Expression)**: The recursive `movie_hierarchy` CTE is created to fetch movie links, meaning if a movie has linked movies (sequels, prequels, etc.), it will fetch them recursively along with their level in the hierarchy.

2. **JOINs**: The query uses multiple JOINs across various tables to gather data about actors, movies, companies associated with movies, and keywords.

3. **COUNT & STRING_AGG**: It counts the number of distinct associated companies per movie while aggregating the keywords associated with those movies into a concatenated string.

4. **Correlated Subquery**: This is used in the `SELECT` statement to count how many times the budget information is available for the movies, providing a more focused analysis rather than just returning all info types.

5. **NULL Logic**: It includes a check for the average level in the hierarchy with a fallback to 0 to handle potential NULL cases to ensure the final query is robust.

6. **HAVING Clause**: It filters to include only those actors who have movies associated with more than one company, emphasizing collaboration in the movie industry.

7. **Ordering**: The final results are ordered by the average link level of movies (highest to lowest) and then by actor names.

This query serves as a benchmark by executing multiple complex SQL constructs together, useful for performance measurement against a dataset of considerable size.

