WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        
    UNION ALL
    
    SELECT 
        link.linked_movie_id AS movie_id,
        child.title,
        child.production_year,
        parent.depth + 1 AS depth
    FROM 
        movie_link link
    JOIN 
        aka_title child ON link.linked_movie_id = child.id
    JOIN 
        MovieHierarchy parent ON link.movie_id = parent.movie_id
)
SELECT 
    p.name AS actor_name,
    a.title AS movie_title,
    a.production_year,
    COUNT(DISTINCT m.id) AS total_movies,
    SUM(CASE WHEN c.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS role_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(COALESCE(CAST(mi.info AS INTEGER), 0)) AS average_info_value
FROM 
    aka_name p
JOIN 
    cast_info c ON p.person_id = c.person_id
JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
JOIN 
    aka_title a ON mh.movie_id = a.id
LEFT JOIN 
    movie_keyword mk ON a.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON a.id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')
WHERE 
    p.name IS NOT NULL
    AND a.production_year >= 2000
GROUP BY 
    p.name, a.title, a.production_year
HAVING 
    COUNT(DISTINCT m.id) > 5
ORDER BY 
    average_info_value DESC
LIMIT 10;

This query utilizes several constructs to demonstrate complex SQL capabilities:
1. A recursive Common Table Expression (CTE) `MovieHierarchy` to build a hierarchy of movies and linked movies.
2. Left joins to combine additional data such as keywords and movie information while allowing NULLs for movies without keywords or information.
3. Aggregation functions like `COUNT`, `SUM`, `STRING_AGG`, and `AVG` to summarize data about actors and their movies.
4. Filtering and grouping based on various criteria, challenging the SQL engine's performance with a complex predicate and grouping conditions.
5. Sorting the results to achieve a meaningful output related to the average rating information while limiting the results to the top 10 entries.
