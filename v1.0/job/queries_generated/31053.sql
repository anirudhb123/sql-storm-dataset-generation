WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
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
    a.name AS actor_name,
    at.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    SUM(CASE 
        WHEN ci.nr_order IS NOT NULL THEN 1 
        ELSE 0 
    END) AS total_roles,
    MAX(CASE 
        WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Height') THEN pi.info 
        ELSE NULL 
    END) AS actor_height
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
JOIN 
    MovieHierarchy mh ON mh.movie_id = ci.movie_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
GROUP BY 
    a.name, at.title, mh.production_year
HAVING 
    COUNT(DISTINCT mk.keyword) > 0 
    AND mh.production_year >= 2000
ORDER BY 
    mh.production_year DESC,
    total_roles DESC,
    a.name ASC;

### Explanation of Constructs Used:

1. **Recursive CTE**: The `WITH RECURSIVE MovieHierarchy` statement is used to build a hierarchy of movies, linking franchises or sequels to their parent movies.

2. **Outer Joins**: A `LEFT JOIN` is used to get additional keyword information and actor height, ensuring that movies are included even if they lack certain details.

3. **Aggregate Functions**: `COUNT(DISTINCT mk.keyword)` is used to count the number of unique keywords associated with each movie. `SUM` is used to count the total roles associated with each actor in the movies.

4. **CASE Statements**: Used to conditionally count roles and retrieve actor height based on specific criteria.

5. **Subqueries**: A subquery within the `HAVING` clause is used to filter actors who have specific keywords associated with their movies and whose movies were produced after 2000.

6. **GROUP BY and ORDER BY Clauses**: The output is grouped by actor name and movie title and ordered by production year (most recent first), number of roles, and actor name.

This query offers a holistic view of the actors, their roles, and relevant associated details, showcasing an intricate use of SQL constructs for retrieving performance benchmarking metrics effectively.
