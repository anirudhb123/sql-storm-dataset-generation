WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS title,
        m.production_year,
        1 AS level,
        ARRAY[m.title] AS path
    FROM 
        aka_title m
    WHERE 
        m.production_year < 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS title,
        m.production_year,
        mh.level + 1 AS level,
        mh.path || m.title
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    mk.keyword,
    COUNT(DISTINCT m.id) AS movie_count,
    AVG(m.production_year) AS avg_production_year,
    MAX(m.production_year) AS latest_production_year,
    MIN(m.production_year) AS earliest_production_year
FROM 
    movie_keyword mk
JOIN 
    aka_title m ON m.id = mk.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = m.id
LEFT JOIN 
    aka_name an ON an.person_id = ci.person_id
LEFT JOIN 
    person_info pi ON pi.person_id = ci.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birth date') 
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT m.id) > 5 
    AND AVG(m.production_year) > 1995
ORDER BY 
    movie_count DESC, 
    avg_production_year ASC
LIMIT 10;


### Explanation:
1. **Common Table Expression (CTE)**: The recursive CTE `MovieHierarchy` builds a hierarchy of movies from the `aka_title` table where the production year is prior to 2000, allowing us to explore linked movies.
  
2. **Joins**: The main query links several tables: `movie_keyword`, `aka_title`, `cast_info`, `aka_name`, and `person_info`. This brings together movie details, keywords, cast information and additionally retrieves specific information about the cast members.

3. **Aggregation**: The query calculates the total movie count, average, maximum, and minimum production years while ensuring only those keywords associated with more than five movies released after 1995 are included.

4. **Ordering and Limit**: Results are ordered by the number of movies in descending order and the average production year in ascending order, with a limit of 10 to focus on the most significant entries.

5. **Use of NULL Logic**: By using left joins, the query can handle cases where there might be no corresponding records in `cast_info` or `person_info`, avoiding loss of records from the main `movie_keyword` table.

This SQL query is well-suited for performance benchmarking as it combines multiple advanced SQL constructs while working with a complex relational schema.
