WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        mlt.linked_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link mlt ON mt.id = mlt.movie_id
    WHERE 
        mt.title IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mt.title,
        mt.production_year,
        mlt.linked_movie_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title mt ON mh.linked_movie_id = mt.id
    JOIN 
        movie_link mlt ON mt.id = mlt.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.movie_title,
    mt.production_year,
    MAX(CASE WHEN ci.person_role_id = (SELECT id FROM role_type WHERE role = 'actor') THEN ci.nr_order END) AS actor_order,
    COUNT(DISTINCT mw.keyword) AS keyword_count,
    AVG(DATEDIFF(CURDATE(), pi.info)) AS average_age,
    STRING_AGG(DISTINCT c.name, ', ') FILTER (WHERE c.country_code IS NOT NULL) AS company_names
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.linked_movie_id
JOIN 
    movie_keyword mw ON mh.linked_movie_id = mw.movie_id
JOIN 
    movie_companies mc ON mh.linked_movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_info mi ON mh.linked_movie_id = mi.movie_id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    mh.level = 1 AND
    (pi.info_type_id IS NULL OR pi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'age%'))
GROUP BY 
    ak.name, 
    mt.movie_title, 
    mt.production_year
HAVING 
    COUNT(DISTINCT ci.person_role_id) > 1
ORDER BY 
    average_age DESC,
    actor_order DESC
LIMIT 1000;

### Explanation of the Query:

1. **CTE (Common Table Expression)**: The `MovieHierarchy` recursively fetches linked movies starting from any movie to build a hierarchy based on their connections.

2. **Outer Joins**: The query uses `LEFT JOIN` to retain all actor names even when there are missing data points for certain relationships (e.g. missing company names or additional info).

3. **Correlated Subqueries**: The query contains a correlated subquery that fetches the `id` of the role type labeled `'actor'` to get the correct role for the count of actors.

4. **Window Functions**: The `MAX()` function calculates the maximum order in which the actor appears in the cast list for their respective movies.

5. **Complex Aggregation**: The query employs multiple aggregation techniques, including `COUNT(DISTINCT ...)` for counting keywords associated with movies, and `STRING_AGG()` to create a comma-separated list of company names.

6. **Complicated Predicates**: The `WHERE` clause filters for movies in the first level of the hierarchy and checks info types for records related to age.

7. **Bizarre SQL Semantics**: By using a `FILTER` clause in the `STRING_AGG()` function, the company names are conditionally aggregated based on their existence, showcasing some unusual SQL functionality.

8. **NULL Logic**: Handling NULLs by checking whether `pi.info_type_id IS NULL` or exists in a specific set, allowing for a flexible group of records.

The purpose of this query would be to benchmark performance across multiple joins, subqueries, and heavy aggregations in a relatively complex data environment such as the one described.
