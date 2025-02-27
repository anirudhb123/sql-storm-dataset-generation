WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    at.title AS Movie_Title,
    ak.name AS Actor_Name,
    COUNT(DISTINCT k.keyword) AS Keyword_Count,
    AVG(CAST(mi.info AS INT)) AS Avg_Movie_Info,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY COUNT(DISTINCT k.keyword) DESC) AS Actor_Rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
WHERE 
    ak.name IS NOT NULL
    AND ak.name != ''
    AND (mh.level <= 3 OR mh.level IS NULL)
GROUP BY 
    at.title, ak.name
HAVING 
    COUNT(DISTINCT k.id) > 2
ORDER BY 
    Actor_Rank;

### Explanation:
- **Recursive CTE (`MovieHierarchy`)** is used to build a hierarchy of movies that were produced after the year 2000, allowing us to get all related movies (linked movies)
- **Main SELECT query** pulls movie titles and actor names, counting distinct keywords related to each movie while also calculating the average budget (if available) from another table using a correlated subquery.
- **Left joins** are used to include keyword and budget information even if some movies may not have them.
- **Window functions** like `ROW_NUMBER` are used to rank actors based on the number of keywords associated with the movies they have appeared in.
- **HAVING clause** filters the results to only show those actors who have contributed to more than two distinct keywords across their movies.

This query involves multiple strategies, reflecting an advanced understanding of SQL constructs you specified.
