WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 5
)

SELECT 
    a.person_id,
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    ARRAY_AGG(DISTINCT at.title ORDER BY at.production_year DESC) AS movie_titles,
    AVG(COALESCE(m.info_type_id, 0)::FLOAT) AS average_info_type_id
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    (SELECT 
         movie_id, 
         AVG(info_type_id) AS info_type_id 
     FROM 
         movie_info 
     GROUP BY 
         movie_id
    ) m ON m.movie_id = c.movie_id
JOIN 
    aka_title at ON at.id = c.movie_id
WHERE 
    a.name IS NOT NULL
    AND a.name <> ''
    AND c.nr_order = 1
GROUP BY 
    a.person_id, a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 3
ORDER BY 
    total_movies DESC, actor_name ASC
LIMIT 10;

This SQL query includes:
- A recursive CTE that builds a hierarchy of movies linked to each other.
- Multiple joins across various tables, including `aka_name`, `cast_info`, and a subquery on `movie_info`.
- Use of the `ARRAY_AGG` function to collect titles of movies in a single field.
- Incorporation of COALESCE to handle potential NULL values in aggregate calculations.
- Complex HAVING clause that filters results based on the movie count.
- ORDER BY clause to sort results based on the total number of movies and actor name. 
- Use of various predicates ensuring data integrity and relevance while leveraging NULL checks.
