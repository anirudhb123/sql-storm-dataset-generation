WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- considering movies from the year 2000 onwards

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    COUNT(DISTINCT kh.keyword) AS total_keywords,
    AVG(mh.level) AS average_link_level,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keyword_list
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5 -- filtering actors with more than 5 movies
ORDER BY 
    total_movies DESC
LIMIT 10;

### Explanation:
1. **Recursive CTE (`movie_hierarchy`)**: This part establishes a hierarchy of movies starting from those released in or after 2000. It includes both direct entries and linked movies.
2. **Main Query**: 
   - `aka_name` is joined with `cast_info` to get actors' information and their associated movies.
   - It includes a join with `movie_keyword` and `keyword` to count distinct keywords related to the movies each actor has been in.
   - A LEFT JOIN with the recursive CTE allows us to calculate the average link level across the hierarchy of movies.
3. **Aggregation and Filtering**: Uses `COUNT`, `STRING_AGG` for concatenating keywords, and filters out actors with fewer than 5 movies.
4. **Ordering and Limiting**: Results are ordered by the number of movies in descending order, capped at the top 10 actors.
