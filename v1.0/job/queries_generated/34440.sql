WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title AS movie_title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    JOIN 
        title t ON m.movie_id = t.id
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        t.title AS movie_title,
        mh.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.movie_id
    JOIN 
        title t ON m.movie_id = t.id
)

SELECT 
    DISTINCT
    a.name AS actor_name,
    m.movie_title,
    m.production_year,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY m.production_year DESC) AS recent_movie
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    MovieHierarchy m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.depth <= 2
    AND (mi.info IS NOT NULL OR k.keyword IS NOT NULL)
ORDER BY 
    actor_name, recent_movie;

### Explanation:
1. **Recursive CTE (`MovieHierarchy`)**: This is used to build a hierarchy of movies starting from the year 2000. It initially selects movies from `aka_title` and `title`, then recursively joins on `movie_link` to find linked movies.
  
2. **Main SELECT Query**: 
   - Joins `cast_info` and `aka_name` to get the actor's name.
   - Joins with the recursive CTE to get the movie details.
   - Left joins to `movie_info` to potentially include film budgets, filtering by a subquery that fetches the `info_type_id` based on the specified condition.
   - Also left joins `movie_keyword` and `keyword` to fetch additional keyword information.

3. **Row Number Window Function**: It generates a sequential number for each actor's movies based on the most recent production year.

4. **Complex WHERE Clause**: This checks for movies within two depths of the hierarchy and insists that at least one piece of information (budget or keyword) must not be NULL.

5. **Order By**: Finally, it orders the resulting data first by actor name and then by the assigned recent movie number.

This query is designed for performance benchmarking by including various advanced SQL features and logic.
