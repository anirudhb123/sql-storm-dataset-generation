WITH RECURSIVE MovieHierarchy AS (
    -- CTE to recursively find all linked movies and their titles
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        at.title AS movie_title,
        1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'Sequel')

    UNION ALL

    SELECT 
        mh.movie_id,
        ml.linked_movie_id,
        at.title AS movie_title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.movie_id
)
SELECT 
    a.title AS Original_Movie,
    mh.movie_title AS Linked_Movie,
    mh.level AS Link_Level,
    COUNT(DISTINCT ci.person_id) AS Total_Cast,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS Avg_Cast_Order,
    STRING_AGG(DISTINCT an.name, ', ') AS Cast_Names
FROM 
    aka_title a
LEFT JOIN 
    MovieHierarchy mh ON a.id = mh.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = a.movie_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
WHERE 
    a.production_year >= 2000
    AND (mh.level IS NULL OR mh.level <= 2)  -- Limit to two levels of linked movies
GROUP BY 
    a.title, mh.movie_title, mh.level
ORDER BY 
    a.title, mh.level;

### Explanation of the SQL Query:
1. **CTE (Common Table Expression)**: The recursive CTE `MovieHierarchy` is defined to explore the hierarchy of movies linked by sequels, starting from the initial linked movie and finding deeper levels of connections.

2. **Main Select Statement**: The main query selects original movie titles from `aka_title`, their linked movies from `MovieHierarchy`, and a few aggregates.
   - **Total_Cast**: Counts unique cast members for the original movies.
   - **Avg_Cast_Order**: Computes the average order of cast members, handling NULL values gracefully.
   - **Cast_Names**: Uses `STRING_AGG` to concatenate names of the cast members into a single string.

3. **Joins**: It effectively combines several tables using both left joins and correlated subqueries to gather relevant data.

4. **Where Conditions**: Ensures that only movies produced from the year 2000 onwards are considered and limits the linked movie hierarchy to two levels.

5. **Grouping and Ordering**: The results are then grouped by the original movies and ordered accordingly.

This query encapsulates a range of SQL features and complexities, making it suitable for performance benchmarking in various database systems.
