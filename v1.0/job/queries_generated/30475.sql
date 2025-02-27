WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mt.episode_of_id
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    AVG(CASE WHEN m.production_year < 2000 THEN m.production_year ELSE NULL END) AS avg_pre_2000_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT mc.movie_id) DESC) AS rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, ak.person_id
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5
ORDER BY 
    total_movies DESC, rank;
This query provides an extensive performance benchmark using several SQL constructs. It utilizes:

- A **recursive CTE (`MovieHierarchy`)** to determine the hierarchy of movies and episodes.
- **Joins** between multiple tables to extract relevant actor and movie information.
- **Aggregate functions** to calculate the total movies an actor has been in and their average production year for movies produced before 2000.
- A string aggregation function (`STRING_AGG`) to compile keywords associated with each movie.
- A **window function** (`ROW_NUMBER()`) to rank actors based on their number of movies.
- **Conditional logic** in the `AVG` calculation and a **HAVING clause** to filter for actors involved in more than 5 movies.
