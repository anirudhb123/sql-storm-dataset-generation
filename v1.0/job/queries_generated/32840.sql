WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000  -- Start from the year 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
)

SELECT 
    p.name AS actor_name,
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY mh.production_year DESC) AS rnk,
    CASE 
        WHEN c.note IS NOT NULL THEN 'Has Note'
        ELSE 'No Note'
    END AS note_status
FROM 
    aka_name p
LEFT OUTER JOIN 
    cast_info c ON p.person_id = c.person_id
LEFT JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
GROUP BY 
    p.id, mh.movie_title, mh.production_year, c.note
HAVING 
    COUNT(DISTINCT c.movie_id) > 1
ORDER BY 
    movie_count DESC, p.name;

### Explanation:

1. **Recursive CTE**: 
   - The `MovieHierarchy` CTE starts from movies released from the year 2000 onward and recursively joins to find episodes belonging to series, maintaining a hierarchy.

2. **Selection of Actors and Movies**: 
   - The main query selects actor names and their associated movies' titles and production years. It uses a `LEFT OUTER JOIN` to include actors who might not have roles in movies from the hierarchy.

3. **Aggregations and Window Functions**: 
   - The `COUNT(DISTINCT c.movie_id)` counts the distinct movies each actor has participated in.
   - The `ROW_NUMBER()` function assigns a rank to actors based on the latest production year of movies they’re involved in.

4. **CASE Statement**: 
   - It evaluates whether the actor has a note associated with their role.

5. **Group and Filter**: 
   - It groups the results by actor and movie information, filtering to include only actors involved in more than one movie.

6. **Order By**: 
   - Results are ordered first by the count of movies and then alphabetically by the actor's name. 

This complex query provides a detailed look into actors' performances over a period, including series roles, while applying various SQL constructs to enhance the output.
