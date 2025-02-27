WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 -- Start from movies after 2000

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
        MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    COALESCE(COUNT(DISTINCT DISTINCT c.movie_id), 0) AS movies_played,
    AVG(mh.production_year) AS average_production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
    AND (mh.level IS NULL OR mh.level < 3) -- Only include movies that are direct or within 2 links away
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 0
ORDER BY 
    movies_played DESC
LIMIT 10;
This query utilizes various features:

- A recursive Common Table Expression (CTE) named `MovieHierarchy` is defined to capture a hierarchy of movies linked to each other through the `movie_link` table, specifically searching for movies released after the year 2000.

- The main query then gathers information about actors from the `aka_name` table, counting distinct movies they have played in and calculating the average production year of those movies.

- It left joins the `cast_info`, `MovieHierarchy`, and `movie_keyword` tables to incorporate movie roles, hierarchical linkage, and keywords, respectively. 

- The `STRING_AGG` function collects all distinct keywords associated with the movies played by each actor.

- There are predicates to filter out NULL names and movies that are either direct or up to two links away. 

- The results are grouped by actor's names, ensuring only those with at least one movie are returned, and ordered by the count of movies played in descending order with a limit of 10 results.
