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
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    p.id AS person_id,
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    c.kind AS cast_kind,
    ROW_NUMBER() OVER(PARTITION BY p.id ORDER BY m.production_year DESC) AS role_rank,
    COUNT(DISTINCT mw.keyword) OVER() AS total_keywords_used
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    MovieHierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN 
    comp_cast_type c ON ci.role_id = c.id
LEFT JOIN 
    movie_keyword mw ON mw.movie_id = m.movie_id
WHERE 
    ci.nr_order <= 5 
    AND m.production_year IS NOT NULL
    AND a.name IS NOT NULL
    AND (c.kind IS NULL OR c.kind = 'Actor')
ORDER BY 
    movie_title, role_rank DESC;

### Explanation of the Query Components:
1. **WITH RECURSIVE CTE (MovieHierarchy)**: This recursive common table expression builds a hierarchy of movies starting from those produced after 2000. It retrieves linked movies through the `movie_link` table.

2. **Main SELECT Statement**:
   - Joins several tables (`cast_info`, `aka_name`, `MovieHierarchy`, and `comp_cast_type`) to gather detailed information about cast members, including the title and production year of movies they appeared in.
   - Utilizes `ROW_NUMBER()` window function to rank roles based on production year per actor.

3. **LEFT JOINs**: Employs outer joins to ensure all actors are listed, even if they do not have a specified role kind or keywords associated with the movies.

4. **WHERE Clause with NULL Logic**: Applies filters to enforce that only relevant rows are selected while allowing for NULL values in roles.

5. **COUNT() with DISTINCT Window Function**: Counts the total distinct keywords related to movies, giving insights into the diversity of movie topics represented.

Overall, this complex query provides a comprehensive performance benchmark involving recursive CTEs, outer joins, window functions, and advanced filtering logic to extract meaningful insights about actors and movies from the provided schema.
