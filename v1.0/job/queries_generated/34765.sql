WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.linked_movie_id,
        a.title AS movie_title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link m
    JOIN 
        aka_title a ON m.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COALESCE(CAST(AVG(ci.nr_order) AS DECIMAL), 0) AS average_cast_order,
    ARRAY_AGG(DISTINCT c.name ORDER BY c.name) AS cast_names,
    COUNT(DISTINCT m.id) AS total_movies_linked,
    COUNT(DISTINCT k.keyword) AS total_keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id AND ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name c ON ci.person_id = c.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    mh.production_year IS NOT NULL
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT c.id) > 1
ORDER BY 
    average_cast_order DESC, 
    mh.production_year ASC;

This query does the following:

1. It defines a recursive Common Table Expression (CTE) called `MovieHierarchy` to construct a hierarchy of movies starting from those produced after the year 2000, but it can include linked movies.

2. The main query then aggregates:
   - The average `nr_order` from the `cast_info` table for the movies in the hierarchy.
   - The distinct names of cast members using `ARRAY_AGG`.
   - The number of total linked movies.
   - The number of distinct keywords associated with each movie.

3. It uses multiple joins to connect `MovieHierarchy` with various tables like `complete_cast`, `cast_info`, `aka_name`, `movie_keyword`, and `keyword`.

4. A `HAVING` clause ensures that only movies with more than one cast member are included.

5. The result is ordered by average cast order descending and production year ascending for clarity on performance across linked movie hierarchies.
