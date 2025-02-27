WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id, 
        mt.title, 
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    ah.actor_name,
    ARRAY_AGG(DISTINCT mh.title) AS linked_movies,
    COUNT(*) FILTER (WHERE mh.production_year >= 2000) AS movies_since_2000,
    AVG(mi.info_length) AS avg_info_length,
    ROW_NUMBER() OVER (PARTITION BY ah.actor_name ORDER BY COUNT(mh.movie_id) DESC) AS actor_rank
FROM
    (SELECT 
         ak.name AS actor_name, 
         ci.movie_id
     FROM 
         aka_name ak
     JOIN 
         cast_info ci ON ak.person_id = ci.person_id) ah
LEFT JOIN 
    movie_hierarchy mh ON ah.movie_id = mh.movie_id
LEFT JOIN 
    (SELECT movie_id, LENGTH(info) AS info_length 
     FROM movie_info) mi ON mh.movie_id = mi.movie_id
GROUP BY 
    ah.actor_name
HAVING 
    COUNT(mh.movie_id) > 5
ORDER BY 
    actor_rank;

### Explanation:
- **Recursive CTE**: We start with the `aka_title` table to get all movies, and recursively find linked movies through `movie_link`, creating a hierarchy of related movies.
- **Aggregates and Filters**: In the select statement, we aggregate linked movie titles, count how many movies were produced since 2000 using a conditional filter, and calculate the average length of information strings.
- **Window Function**: We use a window function to rank actors based on the number of movies they have appeared in.
- **LEFT JOINs**: We join with `cast_info` to find actors, and with `movie_info` to calculate info lengths, allowing for NULLs in links.
- **HAVING clause**: Filters actors who have appeared in more than five movies to focus on more prominent actors.
- **Final Order**: The results are ordered based on actor rank, producing an insightful ranking output for performance benchmarking.
