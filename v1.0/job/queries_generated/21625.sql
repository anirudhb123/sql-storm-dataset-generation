WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        0 AS hierarchy_level
    FROM 
        aka_title mt
    WHERE 
        production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        ml2.title,
        ml2.production_year,
        mh.hierarchy_level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title ml2 ON ml.linked_movie_id = ml2.id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    max(mh.hierarchy_level) AS max_hierarchy,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    SUM(CASE 
            WHEN l.link_type_id IS NOT NULL THEN 1 
            ELSE 0 
        END) AS linked_movies_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    movie_link l ON at.id = l.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id = at.id
WHERE 
    ak.name IS NOT NULL
    AND ak.name NOT IN ('Unknown', 'Uncredited')
    AND at.production_year BETWEEN 1990 AND 2023
GROUP BY 
    ak.name, at.title
HAVING 
    max_hierarchy >= 1
    AND COUNT(DISTINCT mk.keyword) >= 5
ORDER BY 
    max_hierarchy DESC, 
    keyword_count DESC;

### Explanation:
1. **Recursive CTE (`MovieHierarchy`)**: This constructs a hierarchy of linked movies. It retrieves the title and production year for each movie and allows for a variable hierarchy level based on links to other movies.

2. **Main Query**: 
   - Joins `aka_name`, `cast_info`, `aka_title`, and others to compile a list of actors, their films, and perform aggregations.
   - Uses `LEFT JOIN` to connect keywords and linked movies to provide additional context to the findings.

3. **Calculations**:
   - Gets the maximum hierarchy level of linked movies, counts distinct keywords linked to the title, and counts the number of linked movies to the title.
   - Uses `SUM` with a `CASE` statement to handle optional linked movie counting based on `NULL` logic.

4. **Filtering**:
   - Implements various filtering conditions to exclude placeholders (`Unknown`, `Uncredited`), limit years of production between 1990 and 2023, and ensures at least five distinct keywords are associated with the movie.

5. **Ordering and Results**:
   - Orders the final result based on the maximum hierarchy level and count of keywords.

This query tests many SQL constructs and handles complex predicates while ensuring robust filtering, providing insights into the relationships among actors, movies, and their keywords.
