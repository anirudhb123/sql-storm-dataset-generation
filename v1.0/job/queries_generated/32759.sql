WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.kind_id = 1 -- Assuming kind_id = 1 represents 'movie'
    
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
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    COUNT(DISTINCT c.person_id) AS actor_count,
    AVG(mh.level) AS avg_hierarchy_level,
    SUM(mk.keyword IS NOT NULL) AS keyword_count,
    CASE 
        WHEN mt.production_year IS NULL THEN 'Year Unknown'
        ELSE CAST(mt.production_year AS TEXT)
    END AS production_year
FROM 
    cast_info c
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    aka_title mt ON c.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND mt.production_year >= 2000
    AND (ak.name LIKE '%Smith%' OR ak.name LIKE '%Johnson%')
GROUP BY 
    ak.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 1 
ORDER BY 
    actor_count DESC, avg_hierarchy_level ASC;

### Explanation:
1. **Recursive CTE**: The `MovieHierarchy` CTE recursively builds a hierarchy of movies and their sequels or linked movies, allowing us to analyze films in a more complex relational structure.
2. **Outer Joins**: Used in the form of a `LEFT JOIN` to include movies that might not have keywords while still providing actor and movie details.
3. **Aggregations**: We count unique actors, calculate average hierarchy level, and sum the presence of keywords to provide insights into movie characteristics.
4. **Conditional Logic**: Utilizes `CASE` to handle NULL production years, providing a user-friendly label.
5. **Filtering and Grouping**: Focused on actors with specific name patterns and movies produced since 2000, ensuring targeted insights.
6. **Ordering**: The final order emphasizes actor count, making it easier to identify popular films with collaborations and strong keyword presence. 

This query serves multiple analytical purposes in performance benchmarking, exploring actor involvement in films within a complex relationship while maintaining efficiency and clarity.
