WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, 0 AS level
    FROM aka_title mt
    WHERE mt.production_year = (SELECT MAX(production_year) FROM aka_title)

    UNION ALL

    SELECT mt.id, mt.title, mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    SUM(CASE WHEN mt.production_year IS NOT NULL THEN 1 ELSE 0 END) AS produced_movies,
    STRING_AGG(DISTINCT ki.keyword, ', ') AS keywords,
    AVG(mi.info::int) FILTER (WHERE mi.info_type_id = (SELECT id FROM info_type WHERE LOWER(info) LIKE 'budget%')) AS avg_budget,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS actor_ranking
FROM
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.movie_id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id
LEFT JOIN
    (SELECT title, COUNT(*) AS similar_count
     FROM movie_keyword
     GROUP BY title
     HAVING COUNT(*) > 1) subquery ON subquery.title = mt.title
WHERE 
    ak.name IS NOT NULL
    AND (mt.production_year > 2000 OR mt.production_year IS NULL)
    AND NOT EXISTS (
        SELECT 1 
        FROM movie_info_idx mii 
        WHERE mii.movie_id = mt.id AND mii.info_type_id = (SELECT id FROM info_type WHERE LOWER(info) = 'rating')
    )
GROUP BY 
    ak.name, mt.title
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
    AND actor_ranking <= 3
ORDER BY 
    actor_ranking,
    num_companies DESC;

### Query Explanation:
1. **CTE (Common Table Expression)**: The `movie_hierarchy` CTE generates a recursive list of movies starting from the latest production year.

2. **Main Query**: It selects information about actors, movies, and their associated companies, keywords, and budgets.
   
3. **Aggregations**: `COUNT`, `SUM`, `STRING_AGG`, and `AVG` functions are used to calculate the number of companies, produced movies, keywords, and average budget, respectively.

4. **Filters**: Using various filters such as predicates checking for NULL values and production year, as well as subqueries.

5. **Window Functions**: The `ROW_NUMBER()` function ranks actors based on the number of companies tied to their movies.

6. **Outer Joins and NOT EXISTS**: It uses LEFT JOINs for optional relations, and a subquery with `NOT EXISTS` to check certain conditions related to the movie information.

7. **HAVING Clause**: This ensures that only actors with more than zero associated companies and a specific ranking get selected. 

8. **Bizarre Constraints**: The query includes peculiar filtering conditions, such as avoiding movies with certain ratings and checking counts of similar titles.

This query showcases complexity and intricacy in SQL syntax while also embedding logical operations and aggregation capabilities.
