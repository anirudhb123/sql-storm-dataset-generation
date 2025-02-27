WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        CONCAT(mh.movie_title, ' >> ', m.title) AS movie_title,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    mt.movie_title,
    mt.production_year,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY mt.production_year DESC) AS performance_rank,
    COALESCE(mk.keyword, 'No keyword') AS related_keyword,
    COUNT(DISTINCT cc.movie_id) OVER (PARTITION BY ak.id) AS total_movies_as_cast,
    SUM(CASE WHEN cc.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_confirmed
FROM 
    aka_name ak
JOIN 
    cast_info cc ON ak.person_id = cc.person_id
JOIN 
    MovieHierarchy mt ON cc.movie_id = mt.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.movie_id = mk.movie_id
WHERE 
    ak.name IS NOT NULL AND 
    mt.movie_title IS NOT NULL AND 
    mt.level <= 3
ORDER BY 
    performance_rank, actor_name;

This SQL query performs the following actions:

1. **CTE (Common Table Expression) with Recursion**: A `WITH RECURSIVE` clause defines a hierarchy of movies that were produced from the year 2000 onward, capturing both the movies and their respective series relationships.

2. **Main Query**: The main query selects from the `aka_name`, `cast_info`, and hierarchical `MovieHierarchy`, extracting relevant information:
   - Actor names
   - Movie title and production year
   - Ranks actors' performances based on the latest production year using a window function (`ROW_NUMBER()`).
   - It includes a left join to associate keywords with the corresponding movies, using COALESCE to provide a default value for keywords.
   - Counts total movies that the actor has been cast in and sums the confirmed roles using conditional aggregation.

3. **Filtering**: The `WHERE` clause ensures that only non-null names and titles are included and limits the depth of the movie hierarchy to 3 levels.

4. **Ordering**: Results are sorted by performance rank and actor name for easier readability and analysis.

This complex SQL query showcases the use of various SQL features and logical constructs to analyze movie performance based on actor participation.
