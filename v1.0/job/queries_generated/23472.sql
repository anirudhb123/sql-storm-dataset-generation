WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        ARRAY[mt.title] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        a.title,
        mh.path || a.title
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title a ON a.id = ml.linked_movie_id 
    WHERE 
        NOT a.title = ANY(mh.path)  -- prevent cycles in hierarchy
)

SELECT 
    ak.name AS actor_name,
    ARRAY_AGG(DISTINCT mh.title) AS linked_movie_titles,
    COUNT(DISTINCT mh.movie_id) FILTER (WHERE mh.title IS NOT NULL) AS total_linked_movies,
    AVG(pt.production_year) AS average_production_year,
    CASE 
        WHEN COUNT(DISTINCT mh.movie_id) > 5 THEN 'Prolific Actor'
        ELSE 'Less Active Actor' 
    END AS actor_activity_status,
    SUM(CASE WHEN ak.name IS NOT NULL THEN 1 ELSE 0 END) AS non_null_actor_count,
    MAX(COALESCE(CAST(SUBSTRING(ak.name FROM '^[A-Z]') AS CHAR), 'Unknown')) AS starting_letter,
    STRING_AGG(DISTINCT COALESCE(ct.kind, 'Unknown'), ', ') AS company_types_involved,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS rank_by_activity
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ci.person_id = ak.person_id
JOIN 
    MovieHierarchy mh ON mh.movie_id = ci.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id 
LEFT JOIN 
    company_type ct ON ct.id = mc.company_type_id 
LEFT JOIN 
    title t ON t.id = mh.movie_id
LEFT JOIN 
    aka_title at ON at.id = mh.movie_id 
LEFT JOIN 
    (SELECT 
         movie_id, 
         AVG(production_year) AS production_year 
     FROM 
         aka_title 
     GROUP BY 
         movie_id) pt ON pt.movie_id = mh.movie_id
GROUP BY 
    ak.name
ORDER BY 
    rank_by_activity ASC NULLS LAST, 
    actor_name;

### Explanation:
1. **CTE**: A recursive Common Table Expression (`MovieHierarchy`) is used to traverse a potential movie-link hierarchy, accumulating linked movie titles.
2. **JOINs**: Various joins are employed, including left joins on `movie_companies` and `company_type` to gather additional data on the movies.
3. **Aggregation**: The main SELECT aggregates data across movies, including the use of `ARRAY_AGG` to get unique linked movie titles and `COUNT` with a filter to count non-null titles.
4. **CASE Logic**: There are conditional expressions to classify actor activity based on the count of linked movies.
5. **String Functions**: Includes string manipulation using `SUBSTRING` and `STRING_AGG` to gather and format results related to company types.
6. **WINDOW Functions**: Utilizes `ROW_NUMBER()` to rank actors by their activity level in the result set.
7. **NULL Handling**: Uses `COALESCE` to manage potential NULL values in string aggregations and calculations.
8. **Ordering**: Results are ordered to place 'less active actors' at the bottom, indicating a practical use of NULLS LAST.

This complex query provides insights into actors and their linked movies while showcasing advanced SQL features, corner cases, and various functionalities.
