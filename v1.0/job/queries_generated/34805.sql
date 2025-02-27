WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    p.name,
    COUNT(DISTINCT c.id) AS total_movies,
    AVG(mh.level) AS avg_link_depth,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    cast_info c
JOIN 
    aka_name p ON c.person_id = p.person_id
LEFT JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON c.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    p.name IS NOT NULL
GROUP BY 
    p.name
HAVING 
    COUNT(DISTINCT c.id) > 3
ORDER BY 
    total_movies DESC;

This SQL query performs the following complex operations:

1. It uses a recursive Common Table Expression (CTE), `MovieHierarchy`, to create a hierarchy of movies based on links to other movies that were released after 2000.

2. It selects various aggregated data including:
   - The name of the actor/actress.
   - The total count of distinct movies they have been involved in.
   - The average link depth from the hierarchy, indicating how many linked movies down from a starting movie they appear.
   - A string aggregation of distinct keywords associated with their movies.
   - A string aggregation of distinct company names that produced their movies.

3. The query filters out actors/actresses whose names are NULL and ensures that only those who participated in more than 3 movies are included in the results.

4. Finally, it orders the results by the total number of movies in descending order.
