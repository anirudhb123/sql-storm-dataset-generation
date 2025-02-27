WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    DISTINCT
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS number_of_movies,
    AVG(d.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords_associated,
    CASE 
        WHEN COUNT(DISTINCT c.movie_id) > 5 THEN 'Highly Productive Actor'
        WHEN COUNT(DISTINCT c.movie_id) BETWEEN 3 AND 5 THEN 'Moderately Productive Actor'
        ELSE 'Less Productive Actor'
    END AS productivity_category
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    movie_hierarchy d ON c.movie_id = d.movie_id
LEFT JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    a.name IS NOT NULL
    AND d.production_year >= 2000
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 2
ORDER BY 
    number_of_movies DESC;

### Explanation:
1. **CTE (`movie_hierarchy`)**: This recursive Common Table Expression retrieves all movies of type 'movie' from the `aka_title` table and can link movies based on potential sequels or links stored in the `movie_link` table.

2. **Main Query**: 
   - We start from the `aka_name` table to get actors and link to `cast_info` to get the movies they've acted in.
   - A join is performed with the `movie_hierarchy` to restrict to movies produced post-2000.
   - A left join is applied to gather keywords related to each movie. 
   - The `WHERE` clause filters out entries where actor names are NULL and restricts the production year.
   - The `GROUP BY` and aggregate functions calculate the number of unique movies and average production year.

3. **String Aggregation**: We employ `STRING_AGG()` to concatenate all unique keywords associated with each actor.

4. **CASE Statement**: This creates a productivity category based on the count of movies each actor has been part of.

5. **HAVING Clause**: This ensures that we only consider actors that have participated in more than two movies.

6. **Order**: Finally, results are ordered by the number of movies in descending order to highlight the top actors by movie count.
