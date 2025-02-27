WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movies_count,
    AVG(CASE WHEN ti.kind_id IN (1, 2) THEN 1 ELSE 0 END) AS avg_main_role,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    ARRAY_AGG(DISTINCT COALESCE(company.name, 'Unknown')) AS production_companies
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    movie_companies mc ON c.movie_id = mc.movie_id
LEFT JOIN 
    company_name company ON mc.company_id = company.id
LEFT JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
JOIN 
    title ti ON mh.movie_id = ti.id
WHERE 
    a.name IS NOT NULL 
    AND a.name <> ''
GROUP BY 
    a.id
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    movies_count DESC
LIMIT 10;

### Explanation of the SQL Query:

1. **CTE (Common Table Expression)**: The recursive CTE `movie_hierarchy` is constructed to create a hierarchy of movies that are linked together. It starts from the `aka_title` table with movies that have a production year, and recursively includes linked movies through the `movie_link` table.

2. **SELECT Clause**: The main query selects the actor's name from the `aka_name` table and counts the distinct movies they have appeared in using the `cast_info` table. It calculates the average number of main roles based on `kind_id`, aggregates keywords the movies are tagged with, and collects production companies associated with those movies.

3. **LEFT JOINs**: It includes multiple outer joins for associating movie companies and keywords, ensuring that even if there are missing values, the actor information is still returned.

4. **WHERE Clause**: The query filters out actors with null or empty names to ensure data integrity.

5. **GROUP BY and HAVING**: It groups the results by actor ID and filters to show only those actors who have appeared in more than five distinct movies.

6. **ORDER BY and LIMIT**: The results are ordered by the count of movies in descending order, and limited to the top 10 actors.

This query incorporates various SQL constructs such as CTEs, outer joins, aggregate functions, and conditional logic to deliver a comprehensive overview of actors based on their filmography within a certain schema.
