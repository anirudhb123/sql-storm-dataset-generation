WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CAST(0 AS INTEGER) AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS movies_part_of,
    AVG(mh.production_year) AS average_year_of_movies,
    STRING_AGG(DISTINCT at.title, ', ') AS titles,
    SUM(CASE WHEN mc.company_type_id IS NULL THEN 1 ELSE 0 END) AS unlinked_movies_count,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    aka_title at ON mh.movie_id = at.id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    movies_part_of DESC;

This SQL query performs the following tasks:

1. **Recursive CTE** (`MovieHierarchy`) to establish a hierarchy of movies starting from those produced in the year 2000 onwards and includes their linked movies.
2. **SELECT query** that aggregates data about actors from the `aka_name` table who have been cast in more than five movies.
3. It counts distinct movies, calculates the average production year, and aggregates movie titles into a string.
4. It counts movies with unlinked companies and uses a `ROW_NUMBER` window function to rank actors based on their movie participation count.
5. The use of a `LEFT JOIN` with `movie_companies` captures those movies without a linked company.
6. `HAVING` clause filters results to only include actors who have appeared in more than five movies.

