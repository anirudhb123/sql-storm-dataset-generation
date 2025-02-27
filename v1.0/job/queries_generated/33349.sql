WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 3  -- Limit hierarchy depth to avoid excessive recursion
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    COALESCE(NULLIF(a_production_year, 0), 'Unknown Year') AS production_year,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    SUM(CASE 
            WHEN c.role_id IS NOT NULL THEN 1 
            ELSE 0 
        END) AS acting_roles,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keyword_list,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY COUNT(DISTINCT mk.keyword) DESC) AS actor_rank
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    aka_title at ON c.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND at.production_year IS NOT NULL
GROUP BY 
    ak.name, at.title, a_production_year
HAVING 
    COUNT(DISTINCT mk.keyword) > 2
ORDER BY 
    actor_rank, production_year DESC;

### Explanation:
- This SQL query generates a list of actors along with the titles of the movies they acted in, including the production year and keyword data related to those movies.
- A recursive CTE called `MovieHierarchy` is used to build a hierarchy of linked movies, retrieving movies up to 3 levels deep.
- The main query employs outer joins to gather keywords and counts the number of unique keywords associated with each movie.
- The `COALESCE` and `NULLIF` functions handle cases where the production year may be zero or null.
- A window function, `ROW_NUMBER()`, ranks actors based on their number of unique keywords.
- The filtering in the `HAVING` clause ensures that only actors with more than 2 distinct keywords are returned. 
- The query sorts the result set by actor rank and production year.
