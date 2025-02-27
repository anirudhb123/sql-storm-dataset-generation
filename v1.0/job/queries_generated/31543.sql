WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS level,
        m.production_year
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m2.linked_movie_id,
        m2.title,
        mh.level + 1,
        m2.production_year
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    mh.level AS movie_hierarchy_level,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS average_order
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    MovieHierarchy mh ON t.id = mh.movie_id
GROUP BY 
    a.name, t.title, mh.level
HAVING 
    COUNT(DISTINCT k.keyword) > 3 
    AND AVG(c.nr_order) IS NOT NULL
ORDER BY 
    movie_hierarchy_level DESC, keyword_count DESC
LIMIT 100;

This query achieves the following:
1. Creates a recursive Common Table Expression (CTE) to build a movie hierarchy based on linked movies.
2. Joins the `cast_info`, `aka_name`, and `aka_title` tables to get actor and movie details.
3. Uses outer joins to include keywords associated with the movies, counting distinct keywords.
4. Computes the average order of appearance for an actor's roles, handling NULLs with a conditional statement.
5. Groups by actor names and movie titles, while filtering out groups with less than 4 distinct keywords and ensuring average order is present.
6. Orders the results by level in the hierarchy and keyword count, limiting the final output to the top 100 results.
